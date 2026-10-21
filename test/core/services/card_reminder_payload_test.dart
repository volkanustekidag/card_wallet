import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/services/card_reminder_service.dart';

void main() {
  group('CardReminderPayload.tryParse', () {
    test('parses expiry and payment payloads', () {
      final expiry = CardReminderPayload.tryParse('credit-card:1700000000:expiry');
      expect(expiry?.cardId, '1700000000');
      expect(expiry?.kind, CardReminderKind.expiry);

      final payment = CardReminderPayload.tryParse('credit-card:uuid-1:payment');
      expect(payment?.cardId, 'uuid-1');
      expect(payment?.kind, CardReminderKind.payment);
    });

    test('rejects null, empty and malformed payloads', () {
      for (final raw in [
        null,
        '',
        'credit-card',
        'credit-card::expiry',
        'credit-card:1:expiry:extra',
        'iban:1:expiry',
        'credit-card:1:EXPIRY',
        'credit-card:1:payment-0',
      ]) {
        expect(CardReminderPayload.tryParse(raw), isNull, reason: '$raw');
      }
    });
  });
}
