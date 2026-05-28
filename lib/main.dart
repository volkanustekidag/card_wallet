import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wallet_app/core/router/getx_bindings.dart';
import 'package:wallet_app/core/router/getx_routes.dart';
import 'package:wallet_app/core/data/migration/hive_migration_runner.dart';
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/iban_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/loyalty_card/loyalty_card_service.dart';
import 'package:wallet_app/core/data/local_services/auth_services/authentication_service.dart';
import 'package:wallet_app/core/controllers/theme_controller.dart';
import 'package:wallet_app/core/services/analytics_service.dart';
import 'package:wallet_app/core/services/card_reminder_service.dart';
import 'package:wallet_app/core/services/premium_service.dart';
import 'package:wallet_app/core/services/rate_app_service.dart';
import 'package:wallet_app/core/services/widget_data_service.dart';
import 'package:wallet_app/core/services/widget_deep_link_handler.dart';
import 'package:wallet_app/core/styles/app_themes.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/firebase_options.dart';

void main() async {
  // runZonedGuarded catches async errors that escape the framework so
  // Crashlytics can still report them. Bindings must be initialised inside
  // the same zone as runApp.
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // App Check protects the wallet export backend from abuse: every
    // request the app sends carries a short-lived, device-attested
    // token (Apple App Attest on iOS, Play Integrity on Android). The
    // backend verifies the token with Firebase Admin SDK and rejects
    // anything that doesn't carry one — so even if someone extracts
    // the API key from the binary they can't talk to the server.
    //
    // Debug builds can't satisfy hardware attestation (simulator has
    // no Secure Enclave, emulators no Play Services), so they fall
    // back to the debug provider. Whitelist the token printed to the
    // console once in Firebase Console → App Check → Apps → menu →
    // "Manage debug tokens".
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider:
          kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
    );

    // Route framework + platform errors into Crashlytics. Debug builds keep
    // logging to console only so we don't pollute the dashboard.
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (!kDebugMode) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      }
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      if (!kDebugMode) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
      return true;
    };
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);
    await AnalyticsService.instance.setEnabled(!kDebugMode);
    unawaited(AnalyticsService.instance.logAppOpen());
    // Device locale is "good enough" — EasyLocalization may not have applied
    // the saved override yet, but BigQuery only needs the rough cohort split.
    final platformLocale = PlatformDispatcher.instance.locale;
    unawaited(
      AnalyticsService.instance.setLocale(platformLocale.toLanguageTag()),
    );

    await Hive.initFlutter();

    // Run any pending schema migrations *before* services open their boxes
    // — otherwise a service would cache pre-migration records as the
    // "current" state. No-op on every launch after the first one that
    // actually has a migration to run.
    await HiveMigrationRunner.runIfNeeded();

    // Critical-path: auth box must be open before the lock screen renders, and
    // the theme must be resolved before MaterialApp builds (otherwise the lock
    // screen flashes the system theme and then swaps once the box loads).
    final themeBootstrap = await ThemeController.bootstrap();
    await AuthenticationService().init();

    // Non-critical services boot in the background. Card services only matter
    // once the user reaches a card screen, and PremiumService self-recovers if
    // accessed before init completes.
    unawaited(_bootstrapCreditCardsAndReminders());
    unawaited(IbanCardService().init());
    unawaited(LoyaltyCardService().init().then((_) async {
      // Don't wait for the user to wander into the loyalty cards page —
      // the home/lock-screen widget should populate the moment the app
      // has any cards on disk. Reads the encrypted Hive box once,
      // pushes the newest card to the widget container.
      try {
        final cards = await LoyaltyCardService().getAllLoyaltyCards();
        await WidgetDataService.instance.reconcile(cards);
      } catch (e) {
        debugPrint('loyalty widget reconcile error: $e');
      }
    }));
    unawaited(PremiumService.initialize());
    unawaited(RateAppService.instance.init());
    // Widget deep-link handler must capture the cold-launch URI *before*
    // the splash page makes its routing decision. We await this one so
    // the splash can see the pending URI synchronously.
    await WidgetDeepLinkHandler.instance.init();

    Get.put(
      ThemeController(
        initialMode: themeBootstrap.mode,
        box: themeBootstrap.box,
      ),
      permanent: true,
    );

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    runApp(
      EasyLocalization(
        supportedLocales: const [
          Locale("en", "US"),
          Locale("tr", "TR"),
          Locale("de", "DE"),
          Locale("fr", "FR"),
          Locale("es", "ES"),
          Locale("pt", "BR"),
          Locale("it", "IT"),
          Locale("nl", "NL"),
          Locale("pl", "PL"),
        ],
        // Anything else (system in AR, ZH, JA, …) falls back to English.
        // Without this the strings render as raw keys ("loyaltyCardsTitle").
        fallbackLocale: const Locale("en", "US"),
        saveLocale: true,
        path: "assets/docs/lang",
        child: const AppWrapper(),
      ),
    );
  }, (error, stack) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
  });
}

Future<void> _bootstrapCreditCardsAndReminders() async {
  final creditCardService = CreditCardService();
  await creditCardService.init();
  await CardReminderService().init();
  final cards = await creditCardService.getAllCreditCards();
  await CardReminderService().scheduleAllCreditCardReminders(cards);
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({Key? key}) : super(key: key);

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> with WidgetsBindingObserver {
  static const Duration _refreshInterval = Duration(hours: 12);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    RateAppService.instance.scheduleInitialPrompt();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _maybeRefreshSubscription();
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().refreshData();
      }
      RateAppService.instance.scheduleInitialPrompt();
    }
  }

  void _maybeRefreshSubscription() {
    final last = PremiumService.lastVerifiedAt;
    if (last != null && DateTime.now().difference(last) < _refreshInterval) {
      return;
    }
    PremiumService.refreshSubscriptionState();
  }

  @override
  Widget build(BuildContext context) {
    return MyApp();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return GetMaterialApp(
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.routes,
      initialBinding: AppBindings(),
      locale: context.locale,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      title: 'Card Wallet',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeController.themeMode,
      navigatorObservers: [AnalyticsService.instance.observer],
    );
  }
}
