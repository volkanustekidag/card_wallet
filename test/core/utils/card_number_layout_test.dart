import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_scanner_service.dart';
import 'package:wallet_app/core/utils/card_number_layout.dart';
import 'package:wallet_app/core/utils/validators.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_bank_detector.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_number_formatter.dart';

const amex = '378282246310005';
const diners = '30569309025904';
const visa19 = '4111111111111111110';
const visa16 = '4111111111111111';

String _type(String input) {
  final digits = FilteringTextInputFormatter.digitsOnly.formatEditUpdate(
    TextEditingValue.empty,
    TextEditingValue(
      text: input,
      selection: TextSelection.collapsed(offset: input.length),
    ),
  );
  return CardNumberFormatter()
      .formatEditUpdate(TextEditingValue.empty, digits)
      .text;
}

void main() {
  group('grouping', () {
    test('Amex is 4-6-5', () {
      expect(CardNumberLayout.format(amex), '3782 822463 10005');
      expect(_type(amex), '3782 822463 10005');
    });

    test('Diners is 4-6-4', () {
      expect(CardNumberLayout.format(diners), '3056 930902 5904');
      expect(_type(diners), '3056 930902 5904');
    });

    test('19-digit Visa is 4-4-4-4-3', () {
      expect(CardNumberLayout.format(visa19), '4111 1111 1111 1111 110');
      expect(_type(visa19), '4111 1111 1111 1111 110');
    });

    test('16-digit Visa is unchanged', () {
      expect(_type(visa16), '4111 1111 1111 1111');
    });

    test('typing past the network maximum is capped', () {
      expect(_type('${amex}99'), '3782 822463 10005');
      // 36 is always 14 digits.
      expect(_type('3614890064791312'), '3614 890064 7913');
      // 300-305 also has 16-digit co-branded cards: regroup as 4-4-4-4.
      expect(_type('${diners}12'), '3056 9309 0259 0412');
      expect(_type('${visa19}5'), '4111 1111 1111 1111 110');
    });

    test('mask keeps the network layout', () {
      expect(CardNumberLayout.mask(amex), '•••• •••••• •0005');
      expect(CardNumberLayout.mask(visa16), '•••• •••• •••• 1111');
    });
  });

  group('validation', () {
    test('Amex, Diners and 19-digit Visa can be saved', () {
      for (final n in [amex, diners, visa19, visa16]) {
        expect(CardNumberLayout.isValidLength(n), isTrue, reason: n);
        expect(CardValidators.isValidLuhn(n), isTrue, reason: n);
      }
    });

    test('wrong lengths are rejected', () {
      expect(CardNumberLayout.isValidLength('411111111111'), isFalse); // 12
      expect(CardNumberLayout.isValidLength('37828224631000'), isFalse); // Amex 14
      expect(CardNumberLayout.isValidLength('${visa19}1'), isFalse); // 20
    });

    test('networks are detected for the badge', () {
      expect(CardBankDetector.networkFor(amex), CardNetwork.amex);
      expect(CardBankDetector.networkFor(diners), CardNetwork.dinersClub);
      expect(CardBankDetector.networkFor('3095'), CardNetwork.dinersClub);
      expect(CardBankDetector.networkFor('39'), CardNetwork.dinersClub);
      expect(CardBankDetector.networkFor(visa19), CardNetwork.visa);
    });
  });

  group('OCR extraction', () {
    test('finds Amex, Diners and 19-digit numbers', () {
      expect(
        CreditCardScannerService.extractCardNumber('AMEX\n3782 822463 10005\n'),
        amex,
      );
      expect(
        CreditCardScannerService.extractCardNumber('3056 930902 5904'),
        diners,
      );
      expect(
        CreditCardScannerService.extractCardNumber('4111 1111 1111 1111 110'),
        visa19,
      );
    });

    test('ignores trailing dates and non-Luhn numbers', () {
      expect(
        CreditCardScannerService.extractCardNumber(
          'Customer service 0850 222 0 333\n4111-1111-1111-1111 12/30',
        ),
        visa16,
      );
      expect(
        CreditCardScannerService.extractCardNumber('1234 5678 9012 3456'),
        isNull,
      );
    });
  });
}
