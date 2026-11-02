import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Trans;
import 'package:hive/hive.dart';
import 'package:wallet_app/core/controllers/auth_controller.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/data/local_services/auth_services/authentication_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/iban_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/loyalty_card/loyalty_card_service.dart';
import 'package:wallet_app/core/services/ui_prefs.dart';
import 'package:wallet_app/feature/onboarding/onboarding_page.dart';

import '../../helpers/harness.dart';

void main() {
  final h = Harness();

  setUpAll(loadRealFonts);
  setUp(() async {
    await h.setUp();
    await AuthenticationService().openBox();
    await CreditCardService().openBox();
    await IbanCardService().openBox();
    await LoyaltyCardService().openBox();
    await Hive.openBox<dynamic>('app_state');
    Get.put<PremiumController>(FakePremium());
    Get.put(AuthController());
  });
  tearDown(h.tearDown);

  Future<void> open(WidgetTester tester,
      {Size size = const Size(393, 852),
      Locale locale = const Locale('en', 'US')}) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpApp(tester, const OnboardingPage(), locale: locale);
    await tester.pumpAndSettle();
  }

  Future<void> next(WidgetTester tester, String key) async {
    // "Continue" saves the choices to Hive: tap from the real zone.
    await tapIo(tester, find.text(key.tr()));
    await tester.pumpAndSettle();
  }

  testWidgets('all four steps, then home; seen flag and choices saved',
      (tester) async {
    await open(tester);
    expect(find.text('cwObTitle'.tr()), findsOneWidget);
    await next(tester, 'cwGetStarted');

    expect(find.text('cwCarryTitle'.tr()), findsOneWidget);
    await next(tester, 'cwContinue');
    expect(UiPrefs.instance.carry, ['loyalty']);

    expect(find.text('cwFirstTitle'.tr()), findsOneWidget);
    await next(tester, 'cwLater');

    expect(find.text('cwLockTitle'.tr()), findsOneWidget);
    await tapIo(tester, find.text('cwDoneOpen'.tr()));
    expect(find.text('HOME ROUTE'), findsOneWidget);
    expect(await tester.runAsync(OnboardingPage.shouldShow), isFalse);
    expect(h.analytics.containsKey('first_card_picker_skipped'), isTrue);
  });

  testWidgets('"remind me" turns expiry reminders on for cards and new ones',
      (tester) async {
    final card = credit('c1', bank: 'Chase');
    await tester.runAsync(() => CreditCardService().addToCreditCard(card));
    await open(tester);
    await next(tester, 'cwGetStarted');
    await next(tester, 'cwContinue');
    await next(tester, 'cwLater');
    expect(card.expiryReminderEnabled, isFalse);

    await tapIo(tester, find.text('cwRemindExpire'.tr()));
    expect(UiPrefs.instance.remindByDefault.value, isTrue);
    expect(card.expiryReminderEnabled, isTrue);

    await tapIo(tester, find.text('cwRemindExpire'.tr()));
    expect(UiPrefs.instance.remindByDefault.value, isFalse);
    expect(card.expiryReminderEnabled, isFalse);
  });

  testWidgets('nothing picked on "what do you carry": cannot continue',
      (tester) async {
    await open(tester);
    await next(tester, 'cwGetStarted');
    // Loyalty starts selected; turning it off leaves nothing.
    await tester.tap(find.text('cwCarryLoyalty'.tr()));
    await tester.pump();
    await next(tester, 'cwContinue');
    expect(find.text('cwCarryTitle'.tr()), findsOneWidget);
  });

  testWidgets('back goes to the previous step, not out', (tester) async {
    await open(tester);
    await next(tester, 'cwGetStarted');
    await next(tester, 'cwContinue');
    expect(find.text('cwFirstTitle'.tr()), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('cwCarryTitle'.tr()), findsOneWidget);
  });

  for (final locale in const [
    Locale('de', 'DE'),
    Locale('fr', 'FR'),
    Locale('pt', 'BR'),
    Locale('tr', 'TR'),
  ]) {
    testWidgets('every step fits a small phone in ${locale.languageCode}',
        (tester) async {
      // iPhone SE: the tightest screen we support.
      await open(tester, size: const Size(375, 667), locale: locale);
      expect(tester.takeException(), isNull);
      await next(tester, 'cwGetStarted');
      expect(tester.takeException(), isNull);
      await next(tester, 'cwContinue');
      expect(tester.takeException(), isNull);
      await next(tester, 'cwLater');
      expect(tester.takeException(), isNull);
    });
  }
}
