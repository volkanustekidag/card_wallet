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
import 'package:wallet_app/core/services/app_lock_service.dart';
import 'package:wallet_app/core/services/card_reminder_service.dart';
import 'package:wallet_app/core/services/error_reporter.dart';
import 'package:wallet_app/core/services/hive_backup_exclusion.dart';
import 'package:wallet_app/core/services/premium_service.dart';
import 'package:wallet_app/core/services/rate_app_service.dart';
import 'package:wallet_app/core/services/wallet_surfaces_sync.dart';
import 'package:wallet_app/core/services/widget_deep_link_handler.dart';
import 'package:wallet_app/core/styles/app_themes.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/feature/boot/boot_gate.dart';
import 'package:wallet_app/firebase_options.dart';

void main() async {
  // runZonedGuarded catches async errors that escape the framework so
  // Crashlytics can still report them. Bindings must be initialised inside
  // the same zone as runApp.
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();

    // Crash reporting and analytics are not worth a dead app: if Firebase
    // fails to come up, start without it.
    try {
      await _initFirebase();
    } catch (e, st) {
      ErrorReporter.report(e, st, reason: 'initFirebase');
    }

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // runApp is called whatever _boot throws; a failed critical init shows
    // BootErrorPage (retry + support) instead of freezing on the splash.
    await bootAndRunApp(
      boot: _boot,
      wrap: (root) => EasyLocalization(
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
        child: root,
      ),
      app: const AppWrapper(),
    );
  }, (error, stack) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
    }
  });
}

Future<void> _initFirebase() async {
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
  // Uncaught async errors are handled by the platform dispatcher and the
  // app keeps running, so they are non-fatal. Only FlutterError.onError
  // (framework build/layout/paint failures) is reported as fatal.
  PlatformDispatcher.instance.onError = (error, stack) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
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
}

/// Everything that must happen before the app UI is built. Safe to call
/// again: BootGate re-runs it from BootErrorPage's "try again".
///
/// Only the auth box is fatal. Without it we can't tell whether a PIN is
/// set, and letting the user through would skip the lock screen.
Future<void> _boot() async {
  await Hive.initFlutter();
  unawaited(HiveBackupExclusion.apply());

  // Run any pending schema migrations *before* services open their boxes
  // — otherwise a service would cache pre-migration records as the
  // "current" state. No-op on every launch after the first one that
  // actually has a migration to run.
  // A failed migration is reported (non-fatal) inside the runner and
  // retried next launch.
  try {
    await HiveMigrationRunner.runIfNeeded();
  } catch (e, st) {
    ErrorReporter.report(e, st, reason: 'HiveMigrationRunner');
  }

  // The theme must be resolved before MaterialApp builds (otherwise the lock
  // screen flashes the system theme and then swaps once the box loads). A
  // broken theme box falls back to the system theme.
  if (!Get.isRegistered<ThemeController>()) {
    try {
      final themeBootstrap = await ThemeController.bootstrap();
      Get.put(
        ThemeController(
          initialMode: themeBootstrap.mode,
          box: themeBootstrap.box,
        ),
        permanent: true,
      );
    } catch (e, st) {
      ErrorReporter.report(e, st, reason: 'ThemeController.bootstrap');
      Get.put(ThemeController(), permanent: true);
    }
  }

  // Critical-path: auth box must be open before the lock screen renders.
  await AuthenticationService().init();

  _startBackgroundServices();

  // Widget deep-link handler must capture the cold-launch URI *before*
  // the splash page makes its routing decision. We await this one so
  // the splash can see the pending URI synchronously.
  await WidgetDeepLinkHandler.instance.init();

  // Warm re-lock after the app has been in the background. Must be
  // registered before runApp so it observes the very first pause.
  if (!Get.isRegistered<AppLockService>()) {
    Get.put(AppLockService(), permanent: true);
  }
}

bool _backgroundServicesStarted = false;

/// Non-critical services boot in the background. Card services only matter
/// once the user reaches a card screen, and PremiumService self-recovers if
/// accessed before init completes.
void _startBackgroundServices() {
  if (_backgroundServicesStarted) return;
  _backgroundServicesStarted = true;
  _creditCardsReady = _bootstrapCreditCardsAndReminders();
  unawaited(IbanCardService().init().catchError(
        (Object e, StackTrace st) =>
            ErrorReporter.report(e, st, reason: 'IbanCardService.init'),
      ));
  // Once the loyalty box is open, keep the widget, quick tile and Apple
  // Watch in step with it — on launch and on every later change.
  unawaited(LoyaltyCardService()
      .init()
      .then((_) => WalletSurfacesSync.instance.start())
      .catchError(
        (Object e, StackTrace st) =>
            ErrorReporter.report(e, st, reason: 'LoyaltyCardService.init'),
      ));
  unawaited(PremiumService.initialize());
  unawaited(RateAppService.instance.init());
}

/// Credit card box + notification plugin. Reminders themselves are
/// (re)scheduled after the first frame — see [_AppWrapperState] — because
/// their texts are rendered with `.tr()` and must not be baked in before
/// translations are loaded.
Future<void> _bootstrapCreditCardsAndReminders() async {
  await CreditCardService().init();
  await CardReminderService().init();
}

Future<void>? _creditCardsReady;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_rescheduleReminders(context.locale));
    });
  }

  Future<void> _rescheduleReminders(Locale locale) async {
    try {
      await _creditCardsReady;
      await CardReminderService().rescheduleAll(locale: locale);
    } catch (e, st) {
      ErrorReporter.report(e, st, reason: 'rescheduleReminders');
    }
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
