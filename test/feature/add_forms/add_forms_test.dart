import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/iban_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/loyalty_card/loyalty_card_service.dart';
import 'package:wallet_app/core/services/ui_prefs.dart';
import 'package:wallet_app/core/utils/credit_card_label.dart';
import 'package:wallet_app/core/utils/session_prompt_gate.dart';
import 'package:wallet_app/feature/add_credit_card/add_credit_card_page.dart';
import 'package:wallet_app/feature/add_credit_card/controller/add_credit_card_controller.dart';
import 'package:wallet_app/feature/add_iban_card/add_iban_card_page.dart';
import 'package:wallet_app/feature/add_iban_card/controller/add_iban_card_controller.dart';
import 'package:wallet_app/feature/add_loyalty_card/add_loyalty_card_page.dart';
import 'package:wallet_app/feature/add_loyalty_card/controller/add_loyalty_card_controller.dart';
import 'package:wallet_app/feature/credit_cards/controller/credit_card_controller.dart';
import 'package:wallet_app/feature/iban_card/controller/iban_card_controller.dart';
import 'package:wallet_app/feature/loyalty_card/controller/loyalty_card_controller.dart';
import 'package:wallet_app/feature/scanner/scan_analyzer.dart';
import 'package:wallet_app/ui/components/cw_button.dart';

import '../../helpers/harness.dart';

void main() {
  final h = Harness();
  late FakePremium premium;

  setUp(() async {
    await h.setUp();
    // Post-save nudges (PIN, widget, rating) have their own tests.
    SessionPromptGate.markUsed();
    premium = FakePremium();
    Get.put<PremiumController>(premium);
    for (final open in [
      CreditCardService().openBox,
      IbanCardService().openBox,
      LoyaltyCardService().openBox,
    ]) {
      await open();
    }
  });
  tearDown(h.tearDown);

  CwButton submit(WidgetTester tester) =>
      tester.widget<CwButton>(find.byType(CwButton).last);

  Future<void> open(WidgetTester tester, Widget page) async {
    await phoneSurface(tester);
    await pumpApp(tester, const Scaffold(body: Text('HOME')));
    Get.to<void>(() => page);
    await tester.pumpAndSettle();
  }

  group('Bank card form', () {
    setUp(() {
      Get.put(AddCreditCardController());
      Get.put(CreditCardController());
    });

    testWidgets('empty: add is disabled', (tester) async {
      await open(tester, const AddCreditCardPage());
      expect(submit(tester).onPressed, isNull);
    });

    testWidgets('expiry reminder starts on when asked for in onboarding',
        (tester) async {
      UiPrefs.instance.remindByDefault.value = true;
      addTearDown(() => UiPrefs.instance.remindByDefault.value = false);
      await open(tester, const AddCreditCardPage());
      expect(
          Get.find<AddCreditCardController>()
              .currentCard
              .value
              .expiryReminderEnabled,
          isTrue);
    });

    testWidgets('scanner prefill fills number, expiry and name',
        (tester) async {
      await open(
        tester,
        const AddCreditCardPage(
          prefill:
              CardHit('4111111111111111', expiry: '09/29', holder: 'jane roe'),
        ),
      );
      expect(find.text('4111 1111 1111 1111'), findsWidgets);
      expect(find.text('09/29'), findsWidgets);
      expect(find.text('JANE ROE'), findsWidgets);
      expect(submit(tester).onPressed, isNotNull);
    });

    testWidgets('saves without a bank name; shown under its network',
        (tester) async {
      await open(
        tester,
        const AddCreditCardPage(
          prefill:
              CardHit('4111111111111111', expiry: '09/29', holder: 'JANE ROE'),
        ),
      );
      await tapIo(tester, find.byType(CwButton).last);
      expect(find.text('HOME'), findsOneWidget);
      final saved =
          (await tester.runAsync(CreditCardService().getAllCreditCards))!;
      expect(saved, hasLength(1));
      // The bank stays empty (editing shows an empty field); the card is
      // called by its network everywhere it's shown.
      expect(saved.single.bankName, isEmpty);
      expect(creditCardLabel(saved.single), 'Visa');
      expect(saved.single.creditCardNumber.replaceAll(' ', ''),
          '4111111111111111');
    });

    testWidgets('at the free limit: paywall, nothing saved', (tester) async {
      premium.loyaltyLimit = 0;
      await open(
        tester,
        const AddCreditCardPage(
          prefill:
              CardHit('4111111111111111', expiry: '09/29', holder: 'JANE ROE'),
        ),
      );
      await tapIo(tester, find.byType(CwButton).last);
      expect(find.text('PAYWALL'), findsOneWidget);
      await tester.runAsync(() async => Get.back<void>());
      await tester.pumpAndSettle();
      final saved =
          (await tester.runAsync(CreditCardService().getAllCreditCards))!;
      expect(saved, isEmpty);
    });
  });

  group('IBAN form', () {
    setUp(() {
      Get.put(AddIbanCardController());
      Get.put(IbanCardController());
    });

    testWidgets('scanner prefill: grouped IBAN, holder, BIC', (tester) async {
      await open(
        tester,
        const AddIbanCardPage(
          prefill: IbanHit('DE89370400440532013000',
              holder: 'Alex Doe', bic: 'DEUTDEFF'),
        ),
      );
      expect(find.textContaining('DE89 3704 0044 0532 0130 00'), findsWidgets);
      expect(find.text('Alex Doe'), findsWidgets);
      expect(find.text('DEUTDEFF'), findsWidgets);
      expect(find.text('cwIbanInvalid'.tr()), findsNothing);
      expect(submit(tester).onPressed, isNotNull);
    });

    testWidgets('a mistyped IBAN is flagged', (tester) async {
      await open(tester, const AddIbanCardPage());
      await tester.enterText(fieldLabelled('IBAN'), 'DE89370400440532013001');
      await tester.pump();
      expect(find.text('cwIbanInvalid'.tr()), findsOneWidget);
    });

    testWidgets('saves a scanned IBAN', (tester) async {
      await open(
        tester,
        const AddIbanCardPage(
          prefill: IbanHit('DE89370400440532013000',
              holder: 'Alex Doe', bic: 'DEUTDEFF'),
        ),
      );
      await tapIo(tester, find.byType(CwButton).last);
      final saved = (await tester.runAsync(IbanCardService().getAllIbanCards))!;
      expect(saved, hasLength(1));
      expect(saved.single.iban.replaceAll(' ', ''), 'DE89370400440532013000');
      expect(saved.single.swiftCode, 'DEUTDEFF');
    });
  });

  group('Loyalty form', () {
    setUp(() {
      Get.put(AddLoyaltyCardController());
      Get.put(LoyaltyCardController());
    });

    testWidgets('needs a name and a number', (tester) async {
      await open(tester, const AddLoyaltyCardPage());
      expect(submit(tester).onPressed, isNull);
      await tester.enterText(fieldLabelled('cwName'.tr()), 'Corner Cafe');
      await tester.pump();
      expect(submit(tester).onPressed, isNull);
      await tester.enterText(
          fieldLabelled('cwBarcodeNumber'.tr()), '4006381333931');
      await tester.pump();
      expect(submit(tester).onPressed, isNotNull);
    });

    testWidgets('saves the card', (tester) async {
      await open(tester, const AddLoyaltyCardPage());
      await tester.enterText(fieldLabelled('cwName'.tr()), 'Corner Cafe');
      await tester.enterText(
          fieldLabelled('cwBarcodeNumber'.tr()), '4006381333931');
      await tester.pump();
      await tapIo(tester, find.byType(CwButton).last);
      final saved =
          (await tester.runAsync(LoyaltyCardService().getAllLoyaltyCards))!;
      expect(saved.map((c) => c.name), ['Corner Cafe']);
      expect(saved.single.barcode, '4006381333931');
    });
  });
}
