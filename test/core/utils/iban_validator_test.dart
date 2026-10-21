import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/utils/validators.dart';

void main() {
  group('IbanValidator', () {
    test('accepts valid IBANs from supported countries', () {
      for (final iban in [
        'TR330006100519786457841326',
        'TR33 0006 1005 1978 6457 8413 26',
        'DE89370400440532013000',
        'GB82WEST12345698765432',
        'FR1420041010050500013M02606',
        'NL91ABNA0417164300',
        'NO9386011117947', // shortest (15)
        'PL61109010140000071219812874',
        'tr330006100519786457841326', // lower case
      ]) {
        expect(IbanValidator.isValid(iban), isTrue, reason: iban);
      }
    });

    test('rejects a wrong check digit', () {
      expect(IbanValidator.isValid('TR340006100519786457841326'), isFalse);
      expect(IbanValidator.isValid('DE89370400440532013001'), isFalse);
    });

    test('rejects the wrong length for the country', () {
      expect(IbanValidator.isValid('TR33000610051978645784132'), isFalse);
      expect(IbanValidator.isValid('DE8937040044053201300'), isFalse);
    });

    test('rejects junk', () {
      expect(IbanValidator.isValid(''), isFalse);
      expect(IbanValidator.isValid('TR33-0006-1005'), isFalse);
      expect(IbanValidator.isValid('TR33000610051978645784132!'), isFalse);
      expect(IbanValidator.isValid('1234567890123456'), isFalse);
    });
  });
}
