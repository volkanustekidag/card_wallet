import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/services/card_reminder_service.dart';
import 'package:wallet_app/core/utils/card_reminder_rules.dart';

void main() {
  group('CardReminderRules', () {
    test('parses expiry as the final day of the expiry month', () {
      expect(
        CardReminderRules.parseExpiryDate('05 / 26'),
        DateTime(2026, 5, 31),
      );
      expect(
        CardReminderRules.parseExpiryDate('12/2027'),
        DateTime(2027, 12, 31),
      );
      expect(CardReminderRules.parseExpiryDate('13/26'), isNull);
      expect(CardReminderRules.parseExpiryDate('bad'), isNull);
    });

    test('clamps monthly payment day to shorter months', () {
      expect(
        CardReminderRules.nextPaymentDate(DateTime(2026, 2, 10), 31),
        DateTime(2026, 2, 28),
      );
      expect(
        CardReminderRules.nextPaymentDate(DateTime(2026, 2, 28), 31),
        DateTime(2026, 2, 28),
      );
      expect(
        CardReminderRules.nextPaymentDate(DateTime(2026, 3, 31), 31),
        DateTime(2026, 3, 31),
      );
    });

    test('moves payment widget date to next month after due day passes', () {
      expect(
        CardReminderRules.nextPaymentDate(DateTime(2026, 5, 16), 15),
        DateTime(2026, 6, 15),
      );
    });

    test('finds upcoming payment dates even when push reminder is off', () {
      final card = _card(
        paymentReminderEnabled: false,
        paymentDueDay: 8,
      );

      final notices = CardReminderRules.upcomingPayments(
        [card],
        now: DateTime(2026, 5, 2, 13),
      );

      expect(notices, hasLength(1));
      expect(notices.single.targetDate, DateTime(2026, 5, 8));
      expect(notices.single.daysUntil, 6);
    });

    test('does not show payment widget when no payment day exists', () {
      final notices = CardReminderRules.upcomingPayments(
        [_card(paymentDueDay: null)],
        now: DateTime(2026, 5, 2),
      );

      expect(notices, isEmpty);
    });

    test('finds expiry widget dates inside the 60 day window only', () {
      final visible = _card(expirationDate: '06/26');
      final outside = _card(id: '2', expirationDate: '08/26');

      final notices = CardReminderRules.upcomingExpiries(
        [outside, visible],
        now: DateTime(2026, 5, 2),
      );

      expect(notices, hasLength(1));
      expect(notices.single.card, visible);
      expect(notices.single.targetDate, DateTime(2026, 6, 30));
      expect(notices.single.daysUntil, 59);
    });

    test('generates future notification dates and skips past reminders', () {
      final card = _card(
        paymentDueDay: 5,
        paymentReminderDaysBefore: 3,
      );

      final dates = CardReminderRules.paymentReminderDates(
        card,
        now: DateTime(2026, 5, 3, 10),
        count: 2,
      );

      expect(dates, [
        DateTime(2026, 6, 2, 9),
        DateTime(2026, 7, 2, 9),
      ]);
    });

    test('parses notification payloads for reminder navigation', () {
      final payment = CardReminderPayload.tryParse('credit-card:abc:payment');
      final expiry = CardReminderPayload.tryParse('credit-card:42:expiry');

      expect(payment?.cardId, 'abc');
      expect(payment?.kind, CardReminderKind.payment);
      expect(expiry?.cardId, '42');
      expect(expiry?.kind, CardReminderKind.expiry);
      expect(CardReminderPayload.tryParse('credit-card:42:unknown'), isNull);
      expect(CardReminderPayload.tryParse('bad'), isNull);
    });
  });
}

CreditCard _card({
  String id = '1',
  String expirationDate = '05/26',
  bool paymentReminderEnabled = true,
  int? paymentDueDay = 15,
  int paymentReminderDaysBefore = 3,
}) {
  return CreditCard(
    id: id,
    bankName: 'Test Bank',
    creditCardNumber: '4111 1111 1111 1111',
    cardHolder: 'TEST USER',
    expirationDate: expirationDate,
    cardColorId: 1,
    paymentReminderEnabled: paymentReminderEnabled,
    paymentDueDay: paymentDueDay,
    paymentReminderDaysBefore: paymentReminderDaysBefore,
  );
}
