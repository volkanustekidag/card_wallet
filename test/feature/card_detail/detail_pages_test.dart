import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/iban_card_service.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/utils/tag_index.dart';
import 'package:wallet_app/feature/card_detail/bank_card_page.dart';
import 'package:wallet_app/feature/card_detail/iban_page.dart';
import 'package:wallet_app/feature/credit_cards/controller/credit_card_controller.dart';
import 'package:wallet_app/feature/iban_card/controller/iban_card_controller.dart';
import 'package:wallet_app/ui/components/cw_list.dart';

import '../../helpers/harness.dart';

void main() {
  final h = Harness();
  late IbanCard ibanCard;
  late CreditCard bankCard;

  setUp(() async {
    await h.setUp();
    ibanCard = iban(7, bank: 'Deutsche Bank');
    final ibans = IbanCardService();
    await ibans.openBox();
    await ibans.addIbanCard(ibanCard);
    bankCard = credit('c1', bank: 'Chase', expiry: '08/29');
    final credits = CreditCardService();
    await credits.openBox();
    await credits.addToCreditCard(bankCard);
  });
  tearDown(h.tearDown);

  /// Pumps [page] on top of a blank route so popping it is observable.
  Future<void> pushPage(WidgetTester tester, Widget page) async {
    await phoneSurface(tester);
    await pumpApp(tester, const Scaffold(body: SizedBox()));
    Get.to<void>(() => page);
    await tester.pumpAndSettle();
  }

  group('IBAN page', () {
    testWidgets('shows the grouped IBAN, BIC and holder', (tester) async {
      await pushPage(tester, IbanPage(card: ibanCard));
      expect(find.text('DE89 3704 0044 0532 0130 00'), findsWidgets);
      expect(find.text('DEUTDEFF'), findsWidgets);
      expect(find.text('cwAccountHolder'.tr()), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('menu sheet sizes to its three rows', (tester) async {
      await pushPage(tester, IbanPage(card: ibanCard));
      await tester.tap(find.bySemanticsLabel('cwMore'.tr()));
      await tester.pumpAndSettle();
      final group = find.ancestor(
          of: find.text('cwDelete'.tr()), matching: find.byType(CwGroup));
      expect(group, findsOneWidget);
      // Three 52 pt rows plus dividers — nowhere near the screen height.
      expect(tester.getSize(group).height, lessThan(240));
    });

    testWidgets('favourite toggles from the menu and is saved', (tester) async {
      await pushPage(tester, IbanPage(card: ibanCard));
      await tester.tap(find.bySemanticsLabel('cwMore'.tr()));
      await tester.pumpAndSettle();
      await tapIo(tester, find.text('cwFavAdd'.tr()));
      expect(isFavoriteCard(ibanCard), isTrue);

      await tester.tap(find.bySemanticsLabel('cwMore'.tr()));
      await tester.pumpAndSettle();
      expect(find.text('cwFavRemove'.tr()), findsOneWidget);
    });

    testWidgets('delete asks first; cancel keeps the card', (tester) async {
      Get.put(IbanCardController());
      await pushPage(tester, IbanPage(card: ibanCard));
      await tester.tap(find.bySemanticsLabel('cwMore'.tr()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('cwDelete'.tr()));
      await tester.pumpAndSettle();
      expect(find.text('deleteIbanCard'.tr()), findsOneWidget);

      await tester.tapAt(const Offset(200, 40)); // dismiss
      await tester.pumpAndSettle();
      expect(find.byType(IbanPage), findsOneWidget);
      expect(ibanCard.isInBox, isTrue);
    });
  });

  group('Bank card page', () {
    testWidgets('number stays masked until revealed, then hides again',
        (tester) async {
      await pushPage(tester, BankCardPage(card: bankCard));
      expect(find.textContaining('4111 1111'), findsNothing);
      expect(find.textContaining('1111'), findsWidgets);

      await tester.tap(find.text('cwRevealNumber'.tr()));
      await tester.pump();
      expect(find.textContaining('4111 1111 1111 1111'), findsOneWidget);
      expect(
          find.text('cwHidesIn'.tr(args: ['$kRevealSeconds'])), findsOneWidget);

      await tester.pump(const Duration(seconds: kRevealSeconds + 1));
      expect(find.textContaining('4111 1111'), findsNothing);
    });

    testWidgets('tap again hides at once', (tester) async {
      await pushPage(tester, BankCardPage(card: bankCard));
      await tester.tap(find.text('cwRevealNumber'.tr()));
      await tester.pump();
      await tester.tap(find.text('cwHideNumber'.tr()));
      await tester.pump();
      expect(find.textContaining('4111 1111'), findsNothing);
    });

    testWidgets('payment reminder asks for the due day first', (tester) async {
      await pushPage(tester, BankCardPage(card: bankCard));
      final row = find.ancestor(
          of: find.text('cwPaymentDue'.tr()), matching: find.byType(CwRow));
      await tapIo(
          tester, find.descendant(of: row, matching: find.byType(Switch)));
      expect(find.text('cwPickDueDay'.tr()), findsOneWidget);

      await tapIo(tester, find.text('15'));
      expect(bankCard.paymentDueDay, 15);
      expect(bankCard.paymentReminderEnabled, isTrue);
      expect(find.text('cwPaymentDueOn'.tr(args: ['15'])), findsOneWidget);
    });

    testWidgets('dismissing the day picker leaves the reminder off',
        (tester) async {
      await pushPage(tester, BankCardPage(card: bankCard));
      final row = find.ancestor(
          of: find.text('cwPaymentDue'.tr()), matching: find.byType(CwRow));
      await tester.tap(find.descendant(of: row, matching: find.byType(Switch)));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(200, 40));
      await tester.pumpAndSettle();
      expect(bankCard.paymentReminderEnabled, isFalse);
      expect(bankCard.paymentDueDay, isNull);
    });

    testWidgets('expiry reminder switch saves the card', (tester) async {
      await pushPage(tester, BankCardPage(card: bankCard));
      final row = find.ancestor(
          of: find.text('cwCardExpiresOn'.tr(args: ['08/29'])),
          matching: find.byType(CwRow));
      await tapIo(tester, row);
      expect(bankCard.expiryReminderEnabled, isTrue);
    });

    testWidgets('delete confirmed: card removed and page closed',
        (tester) async {
      Get.put(CreditCardController());
      await pushPage(tester, BankCardPage(card: bankCard));
      await tester.tap(find.bySemanticsLabel('cwMore'.tr()));
      await tester.pumpAndSettle();
      await tapIo(tester, find.text('cwDelete'.tr()));
      expect(find.text('deleteCreditCard'.tr()), findsOneWidget);
      await tapIo(tester, find.text('yes'.tr()).last);
      expect(find.byType(BankCardPage), findsNothing);
      expect(bankCard.isInBox, isFalse);
    });
  });
}
