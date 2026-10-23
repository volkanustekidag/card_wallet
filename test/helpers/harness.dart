import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet_app/core/constants/app_locales.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/services/premium_service.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/enums/card_limit_type.dart';
import 'package:wallet_app/core/services/analytics_service.dart';
import 'package:wallet_app/core/services/card_reminder_service.dart';
import 'package:wallet_app/core/widgets/bank_logo.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';

/// Shared setup for screen tests: a temp Hive dir, an in-memory Keychain,
/// silent analytics, no-op plugin channels and the real translations
/// ([app] loads them; find text with `'key'.tr()`).
class Harness {
  late Directory dir;
  final keychain = <String, String>{};
  final analytics = <String, Map<String, Object>?>{};
  final channelCalls = <String, List<MethodCall>>{};

  static const _channels = [
    'plugins.it_nomads.com/flutter_secure_storage',
    'home_widget',
    'plugins.flutter.io/path_provider',
    'github.com/aaassseee/screen_brightness',
    'dev.fluttercommunity.plus/wakelock_plus',
    'dev.fluttercommunity.plus/sensors/method',
    // Event channels answer listen / cancel on a method channel of the
    // same name; no events are ever sent.
    'dev.fluttercommunity.plus/sensors/accelerometer',
    'dev.fluttercommunity.plus/sensors/user_accel',
    'dev.fluttercommunity.plus/sensors/gyroscope',
    'dev.fluttercommunity.plus/sensors/magnetometer',
    'dev.fluttercommunity.plus/share',
    'plugins.flutter.io/local_auth',
    'dexterous.com/flutter/local_notifications',
    'flutter_timezone',
    'plugins.flutter.io/url_launcher',
    'dev.fluttercommunity.plus/package_info',
  ];

  TestDefaultBinaryMessenger get _messenger =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  Future<void> setUp() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    EasyLocalization.logger.enableBuildModes = [];
    dir = await Directory.systemTemp.createTemp('cw_screen_test');
    Hive.init(dir.path);
    Get.testMode = true;
    AnalyticsService.debugSink = (name, params) => analytics[name] = params;
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
    for (final name in _channels) {
      m.setMockMethodCallHandler(MethodChannel(name), (call) async {
        channelCalls.putIfAbsent(name, () => []).add(call);
        return _answer(name, call);
      });
    }
    BankLogo.cacheManager = _NoNetworkCache();
    CardReminderService.debugNotificationsAllowed = true;
    // A singleton caching its init future: started inside one test's
    // fake-async zone it would never complete for the next test.
    try {
      await CardReminderService().init();
    } catch (_) {}
  }

  Object? _answer(String channel, MethodCall call) {
    if (channel.endsWith('flutter_secure_storage')) {
      final args = (call.arguments as Map?) ?? const {};
      final key = args['key'] as String?;
      switch (call.method) {
        case 'read':
          return keychain[key];
        case 'write':
          keychain[key!] = args['value'] as String;
          return null;
        case 'containsKey':
          return keychain.containsKey(key);
        case 'delete':
          keychain.remove(key);
          return null;
        case 'readAll':
          return keychain;
      }
      return null;
    }
    if (channel.endsWith('path_provider')) return dir.path;
    if (channel == 'flutter_timezone') return 'UTC';
    if (channel.endsWith('local_notifications')) {
      switch (call.method) {
        case 'initialize':
        case 'areNotificationsEnabled':
        case 'requestNotificationsPermission':
        case 'requestPermissions':
          return true;
        case 'pendingNotificationRequests':
        case 'getActiveNotifications':
          return <Object>[];
      }
      return null;
    }
    if (channel.endsWith('local_auth')) {
      return call.method == 'getAvailableBiometrics' ? <String>[] : false;
    }
    if (channel.endsWith('screen_brightness')) return 0.5;
    if (channel.endsWith('package_info')) {
      return {
        'appName': 'Deckard',
        'packageName': 'com.cardwallet',
        'version': '2.2.0',
        'buildNumber': '45',
      };
    }
    return null;
  }

  Future<void> tearDown() async {
    CardReminderService.debugNotificationsAllowed = null;
    Get.reset();
    AnalyticsService.debugSink = null;
    _messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    for (final name in _channels) {
      _messenger.setMockMethodCallHandler(MethodChannel(name), null);
    }
    // A Hive write started inside a test's fake-async zone never finishes
    // and would hang here forever; fail loudly instead (see [tapIo]).
    await Hive.close().timeout(const Duration(seconds: 5), onTimeout: () {
      throw StateError('Hive.close() hung: a write ran in fake async. '
          'Trigger it with tapIo().');
    });
    try {
      await dir.delete(recursive: true);
    } catch (_) {}
  }
}

/// Serves a fixed wallet instead of opening Hive boxes.
class FakeHome extends HomeController {
  int refreshes = 0;

  FakeHome({
    List<CreditCard> credits = const [],
    List<IbanCard> ibans = const [],
    List<LoyaltyCard> loyalties = const [],
  }) {
    set(credits: credits, ibans: ibans, loyalties: loyalties);
  }

  void set({
    List<CreditCard> credits = const [],
    List<IbanCard> ibans = const [],
    List<LoyaltyCard> loyalties = const [],
  }) {
    creditCards.assignAll(credits);
    ibanCards.assignAll(ibans);
    loyaltyCards.assignAll(loyalties);
    walletItems.assignAll(
        mergeAndSort(credits: credits, ibans: ibans, loyalties: loyalties));
    isInitialLoading.value = false;
  }

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  void refreshData() => refreshes++;
}

/// Premium state and stored counts without the store plugin.
class FakePremium extends PremiumController {
  final RxBool _premium;
  bool get premium => _premium.value;
  set premium(bool v) => _premium.value = v;
  int loyaltyLimit;
  int creditLimit;
  int ibanLimit;
  int storedLoyalty;

  /// Defaults are the real free plan (PremiumService).
  FakePremium({
    bool premium = false,
    this.loyaltyLimit = PremiumService.maxLoyaltyCardsForFree,
    this.creditLimit = PremiumService.maxCreditCardsForFree,
    this.ibanLimit = PremiumService.maxIbanCardsForFree,
    this.storedLoyalty = 0,
  }) : _premium = premium.obs;

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  bool get isPremium => premium;

  @override
  bool canAddMoreLoyaltyCards(int currentCount) =>
      premium || currentCount < loyaltyLimit;

  @override
  bool canAddMoreCreditCards(int currentCount) =>
      premium || currentCount < creditLimit;

  @override
  bool canAddMoreIbanCards(int currentCount) =>
      premium || currentCount < ibanLimit;

  @override
  Future<int> getStoredCardCount(CardLimitType type) async => storedLoyalty;
}

LoyaltyCard loyalty(
  String id,
  String name, {
  String barcode = '4006381333931',
  String format = 'EAN_13',
  List<String>? tags,
  int? useCount,
  List<int>? usageLog,
  DateTime? createdAt,
  String? notes,
  String? frontPhoto,
  String? backPhoto,
}) =>
    LoyaltyCard(
      frontPhoto: frontPhoto,
      backPhoto: backPhoto,
      id: id,
      name: name,
      barcode: barcode,
      barcodeFormat: format,
      colorId: 0,
      tags: tags,
      useCount: useCount,
      usageLog: usageLog,
      lastUsedAt: usageLog == null || usageLog.isEmpty
          ? null
          : DateTime.fromMillisecondsSinceEpoch(usageLog.last),
      createdAt: createdAt,
      notes: notes,
    );

CreditCard credit(
  String id, {
  String bank = 'Chase',
  String number = '4111111111111111',
  String expiry = '12/30',
  int? dueDay,
  bool paymentReminder = false,
  List<String>? tags,
}) =>
    CreditCard(
      id: id,
      bankName: bank,
      creditCardNumber: number,
      cardHolder: 'ALEX DOE',
      expirationDate: expiry,
      cardColorId: 0,
      paymentDueDay: dueDay,
      paymentReminderEnabled: paymentReminder,
      tags: tags,
    );

IbanCard iban(int id, {String bank = 'Deutsche Bank', List<String>? tags}) =>
    IbanCard(
      id: id,
      bankName: bank,
      cardHolder: 'Alex Doe',
      iban: 'DE89370400440532013000',
      swiftCode: 'DEUTDEFF',
      tags: tags,
    );

/// A phone-sized surface (iPhone 15: 393 x 852 pt).
Future<void> phoneSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(393, 852));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

/// Reads the app's JSON files straight from disk: no async asset bundle,
/// so a single pump has the strings in place.
class _DiskLoader extends AssetLoader {
  const _DiskLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final exact = File('$path/${locale.toLanguageTag()}.json');
    final file = exact.existsSync()
        ? exact
        : Directory(path).listSync().whereType<File>().firstWhere(
            (f) => f.uri.pathSegments.last.startsWith(locale.languageCode));
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }
}

/// [home] inside the app's localisation (English unless [locale]) and a
/// light or dark theme. Pump, then `await tester.pumpAndSettle()` once.
Widget app(
  Widget home, {
  ThemeMode mode = ThemeMode.light,
  Locale locale = const Locale('en', 'US'),
}) =>
    EasyLocalization(
      supportedLocales: kAppLocales,
      fallbackLocale: kFallbackLocale,
      startLocale: locale,
      saveLocale: false,
      useFallbackTranslations: true,
      path: 'assets/docs/lang',
      assetLoader: const _DiskLoader(),
      child: Builder(
        builder: (context) => GetMaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          themeMode: mode,
          theme: ThemeData(brightness: Brightness.light),
          darkTheme: ThemeData(brightness: Brightness.dark),
          home: home,
          // Stand-ins for routes screens push by name.
          getPages: [
            GetPage(name: '/premium', page: () => const _Stub('PAYWALL')),
            GetPage(name: '/settings', page: () => const _Stub('SETTINGS')),
            GetPage(name: '/home', page: () => const _Stub('HOME ROUTE')),
            GetPage(name: '/auth', page: () => const _Stub('LOCK SCREEN')),
            GetPage(name: '/pinAction', page: () => const _Stub('PIN')),
          ],
        ),
      ),
    );

/// Pumps [home] via [app] and lets the translations load.
Future<void> pumpApp(
  WidgetTester tester,
  Widget home, {
  ThemeMode mode = ThemeMode.light,
  Locale locale = const Locale('en', 'US'),
}) async {
  await tester.pumpWidget(app(home, mode: mode, locale: locale));
  for (var i = 0; i < 50 && find.byWidget(home).evaluate().isEmpty; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump();
  }
  await tester.pump();
}

/// Taps [finder] in the real zone and lets the disk IO it starts (Hive
/// writes) finish, then settles the frame. A write started inside the
/// test's fake-async zone never completes and hangs `Hive.close()`.
Future<void> tapIo(WidgetTester tester, Finder finder) async {
  await tester.runAsync(() => tester.tap(finder));
  await settleIo(tester);
}

/// Real IO (real zone) and widget futures (fake zone) wait on each other,
/// so give each a turn until nothing is animating for a few rounds.
Future<void> settleIo(WidgetTester tester) async {
  var quiet = 0;
  // Opening an encrypted box and writing it takes ~1 s of real time on a
  // cold test isolate, with no frames to show for it.
  for (var i = 0; i < 80 && (i < 30 || quiet < 4); i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await tester.pump(const Duration(milliseconds: 50));
    quiet = tester.binding.hasScheduledFrame ? 0 : quiet + 1;
  }
  // Not pumpAndSettle: real IO may still be finishing and only advances
  // in runAsync, so fake time alone could spin forever.
  await tester.pump(const Duration(milliseconds: 400));
}

/// Pushes [page] from the real zone so whatever its initState writes to
/// Hive (e.g. recording a barcode use) completes; see [tapIo].
Future<void> pushIo(WidgetTester tester, Widget page) async {
  // The first build (initState) must run here, in the real zone.
  await tester.runAsync(() async {
    Get.to<void>(() => page);
    await tester.pump();
  });
  await settleIo(tester);
}

class _Stub extends StatelessWidget {
  final String label;
  const _Stub(this.label);

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(label)));
}

/// The text input inside the form field labelled [label].
Finder fieldLabelled(String label) => find.descendant(
      of: find.ancestor(
        of: find.text(label),
        matching: find
            .byWidgetPredicate((w) => w.runtimeType.toString() == 'CwField'),
      ),
      matching: find.byType(EditableText),
    );

/// Logos fail at once (the monogram shows): no network, no cache database.
class _NoNetworkCache implements BaseCacheManager {
  @override
  Stream<FileResponse> getFileStream(String url,
          {String? key,
          Map<String, String>? headers,
          bool withProgress = false}) =>
      Stream<FileResponse>.error(const HttpExceptionWithStatus(404, 'offline'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

bool _fontsLoaded = false;

/// Real glyph widths for overflow checks: the default test font draws every
/// character as a 1 em square, about twice as wide as real text. Arial
/// stands in for the system font (Roboto / SF Pro have similar metrics).
Future<void> loadRealFonts() async {
  if (_fontsLoaded) return;
  _fontsLoaded = true;
  ByteData bytes(String path) =>
      ByteData.sublistView(File(path).readAsBytesSync());
  final sans = FontLoader('Roboto');
  for (final f in ['Arial.ttf', 'Arial Bold.ttf']) {
    final file = File('/System/Library/Fonts/Supplemental/$f');
    if (file.existsSync()) sans.addFont(Future.value(bytes(file.path)));
  }
  await sans.load();
  final mono = FontLoader('JetBrainsMono');
  for (final w in ['Medium', 'SemiBold']) {
    mono.addFont(Future.value(
        bytes('assets/fonts/jetbrains_mono/JetBrainsMono-$w.ttf')));
  }
  await mono.load();
  final brand = FontLoader('InstrumentSans')
    ..addFont(Future.value(
        bytes('assets/fonts/instrument_sans/InstrumentSans-Bold.ttf')));
  await brand.load();
}

/// Feeds one accelerometer reading (m/s², portrait upright is y ≈ 9.8).
Future<void> tilt(WidgetTester tester, double x, double y) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'dev.fluttercommunity.plus/sensors/accelerometer',
    const StandardMethodCodec().encodeSuccessEnvelope(<double>[
      x,
      y,
      0,
      DateTime.now().microsecondsSinceEpoch.toDouble(),
    ]),
    (_) {},
  );
  await tester.pump();
}
