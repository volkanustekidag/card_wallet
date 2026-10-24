import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/controllers/auth_controller.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/controllers/theme_controller.dart';
import 'package:wallet_app/core/data/local_services/auth_services/authentication_service.dart';
import 'package:wallet_app/core/services/barcode_display_boost.dart';
import 'package:wallet_app/core/services/card_reminder_service.dart';
import 'package:wallet_app/core/services/ui_prefs.dart';
import 'package:wallet_app/feature/import/import_page.dart';
import 'package:wallet_app/feature/settings/widgets/settings_body.dart';
import 'package:wallet_app/ui/components/cw_list.dart';

import '../../helpers/harness.dart';

void main() {
  final h = Harness();
  late ThemeController theme;

  setUpAll(loadRealFonts);
  setUp(() async {
    await h.setUp();
    await AuthenticationService().openBox();
    final boot = await ThemeController.bootstrap();
    theme = Get.put(ThemeController(initialMode: boot.mode, box: boot.box));
    Get.put<PremiumController>(FakePremium());
    Get.put(AuthController());
    await UiPrefs.instance.load();
    UiPrefs.instance.upNext.value = true;
    BarcodeDisplayBoost.instance.enabled.value = true;
  });
  tearDown(h.tearDown);

  Future<void> open(WidgetTester tester,
      {Locale locale = const Locale('en', 'US')}) async {
    await phoneSurface(tester);
    await pumpApp(tester, const Scaffold(body: SafeArea(child: SettingsBody())),
        locale: locale);
    await tester.pump(const Duration(milliseconds: 100));
  }

  Finder rowSwitch(String title) => find.descendant(
        of: find.ancestor(of: find.text(title), matching: find.byType(CwRow)),
        matching: find.byType(CwSwitch),
      );

  testWidgets('Up Next can be turned off and the choice is kept',
      (tester) async {
    await open(tester);
    await tester.ensureVisible(find.text('cwUpNextSetting'.tr()));
    await tester.pumpAndSettle();
    expect(tester.widget<CwSwitch>(rowSwitch('cwUpNextSetting'.tr())).value,
        isTrue);
    await tapIo(tester, find.text('cwUpNextSetting'.tr()));
    expect(UiPrefs.instance.upNext.value, isFalse);
    expect(tester.widget<CwSwitch>(rowSwitch('cwUpNextSetting'.tr())).value,
        isFalse);

    UiPrefs.instance.upNext.value = true;
    await tester.runAsync(UiPrefs.instance.load);
    expect(UiPrefs.instance.upNext.value, isFalse);
  });

  group('notifications row', () {
    late List<String> calls;
    setUp(() {
      calls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('flutter.baseflow.com/permissions/methods'),
              (call) async {
        calls.add(call.method);
        return true;
      });
    });
    tearDown(() {
      CardReminderService.debugNotificationsAllowed = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('flutter.baseflow.com/permissions/methods'),
              null);
    });

    Future<void> tapRow(WidgetTester tester) async {
      await tester.ensureVisible(find.text('notificationsRowTitle'.tr()));
      await tester.pumpAndSettle();
      await tapIo(tester, find.text('notificationsRowTitle'.tr()));
    }

    testWidgets('off: asks for the permission, not the system settings',
        (tester) async {
      CardReminderService.debugNotificationsAllowed = false;
      await open(tester);
      await settleIo(tester);
      expect(find.text('notificationsStatusDisabled'.tr()), findsOneWidget);
      await tapRow(tester);
      expect(calls, isNot(contains('openAppSettings')));
    });

    testWidgets('on: opens the system settings to change it', (tester) async {
      CardReminderService.debugNotificationsAllowed = true;
      await open(tester);
      await settleIo(tester);
      await tapRow(tester);
      expect(calls, contains('openAppSettings'));
    });
  });

  testWidgets('max brightness for barcodes toggles', (tester) async {
    await open(tester);
    await tester.ensureVisible(find.text('barcodeBrightnessTitle'.tr()));
    await tester.pumpAndSettle();
    await tapIo(tester, find.text('barcodeBrightnessTitle'.tr()));
    expect(BarcodeDisplayBoost.instance.enabled.value, isFalse);
  });

  testWidgets('appearance: pick dark from the sheet', (tester) async {
    await open(tester);
    await tester.scrollUntilVisible(find.text('cwAppearance'.tr()), 300);
    await tester.ensureVisible(find.text('cwAppearance'.tr()));
    await tester.pumpAndSettle();
    await tapIo(tester, find.text('cwAppearance'.tr()));
    await tapIo(tester, find.text('themeDark'.tr()).last);
    expect(theme.appThemeMode, AppThemeMode.dark);
  });

  testWidgets('without a PIN: lock off, no auto-lock or change-PIN rows',
      (tester) async {
    await open(tester);
    expect(tester.widget<CwSwitch>(rowSwitch('cwLockApp'.tr())).value, isFalse);
    expect(find.text('autoLock'.tr()), findsNothing);
    expect(find.text('chanPIN'.tr()), findsNothing);
  });

  testWidgets('import row opens the import screen', (tester) async {
    await open(tester);
    await tester.scrollUntilVisible(find.text('cwImportRow'.tr()), 300);
    await tester.ensureVisible(find.text('cwImportRow'.tr()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('cwImportRow'.tr()));
    await tester.pumpAndSettle();
    expect(find.byType(ImportPage), findsOneWidget);
  });

  for (final locale in const [Locale('de', 'DE'), Locale('tr', 'TR')]) {
    testWidgets('no overflow in ${locale.languageCode}', (tester) async {
      await open(tester, locale: locale);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
