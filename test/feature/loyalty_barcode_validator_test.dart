import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/feature/loyalty_card/loyalty_barcode_validator.dart';
import 'package:wallet_app/feature/loyalty_card/widgets/barcode_renderer.dart';

BarcodeIssue? _issue(String value, String format) =>
    LoyaltyBarcodeValidator.validate(value, format).issue;

void main() {
  rendererTests();

  group('valid codes pass', () {
    for (final (value, format) in [
      ('4006381333931', 'EAN_13'),
      ('96385074', 'EAN_8'),
      ('036000291452', 'UPC_A'),
      ('04252614', 'UPC_E'),
      ('01234565', 'UPC_E'),
      ('12345678', 'ITF'),
      ('ABC-123', 'CODE_39'),
      ('member#42', 'CODE_128'),
      ('https://example.com', 'QR_CODE'),
    ]) {
      test('$format $value', () {
        expect(_issue(value, format), isNull);
        expect(LoyaltyBarcodeValidator.canEncode(value, format), isTrue);
      });
    }
  });

  test('empty and whitespace-only values are never encodable', () {
    for (final format in ['CODE_128', 'EAN_13', 'ITF', 'QR_CODE']) {
      expect(_issue('', format), BarcodeIssue.empty);
      expect(_issue('   ', format), BarcodeIssue.empty);
      expect(LoyaltyBarcodeValidator.canEncode('', format), isFalse);
    }
  });

  test('wrong check digit is caught for EAN/UPC', () {
    expect(_issue('4006381333932', 'EAN_13'), BarcodeIssue.checkDigit);
    expect(_issue('96385075', 'EAN_8'), BarcodeIssue.checkDigit);
    expect(_issue('036000291453', 'UPC_A'), BarcodeIssue.checkDigit);
    expect(_issue('04252615', 'UPC_E'), BarcodeIssue.checkDigit);
  });

  test('length is checked with the expected count', () {
    final check = LoyaltyBarcodeValidator.validate('400638133393', 'EAN_13');
    expect(check.issue, BarcodeIssue.length);
    expect(check.expectedLength, 13);
    expect(_issue('0425261', 'UPC_E'), BarcodeIssue.length);
  });

  test('digit formats reject letters', () {
    expect(_issue('40063813339A', 'EAN_13'), BarcodeIssue.digitsOnly);
    expect(_issue('12AB', 'ITF'), BarcodeIssue.digitsOnly);
  });

  test('odd-length ITF is rejected (passes verify, throws while painting)', () {
    expect(_issue('1234567', 'ITF'), BarcodeIssue.evenLength);
    expect(LoyaltyBarcodeValidator.canEncode('1234567', 'ITF'), isFalse);
  });

  test('encoder-only failures are reported as notEncodable', () {
    // UPC-E needs number system 0 or 1.
    expect(_issue('24252614', 'UPC_E'), BarcodeIssue.notEncodable);
    // Code 39 has no lowercase.
    expect(_issue('abc', 'CODE_39'), BarcodeIssue.notEncodable);
  });

  group('suggestFormat', () {
    test('valid 13 digits typed under UPC-A suggests EAN-13', () {
      expect(
        LoyaltyBarcodeValidator.suggestFormat('4006381333931', 'UPC_A'),
        'EAN_13',
      );
    });

    test('a number with a bad check digit falls back to Code 128', () {
      expect(
        LoyaltyBarcodeValidator.suggestFormat('4006381333932', 'EAN_13'),
        'CODE_128',
      );
    });

    test('non-ASCII text falls back to QR', () {
      expect(
        LoyaltyBarcodeValidator.suggestFormat('Üye-ğ', 'CODE_128'),
        'QR_CODE',
      );
    });

    test('empty value has no suggestion', () {
      expect(LoyaltyBarcodeValidator.suggestFormat(' ', 'EAN_13'), isNull);
    });
  });

  test('gtinCheckDigit matches known GTINs', () {
    expect(LoyaltyBarcodeValidator.gtinCheckDigit('400638133393'), 1);
    expect(LoyaltyBarcodeValidator.gtinCheckDigit('9638507'), 4);
    expect(LoyaltyBarcodeValidator.gtinCheckDigit('03600029145'), 2);
  });
}

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void rendererTests() {
  group('BarcodeRenderer', () {
    testWidgets('empty value never reaches BarcodeWidget', (tester) async {
      for (final format in ['CODE_128', 'EAN_13', 'QR_CODE']) {
        await tester.pumpWidget(
          _host(BarcodeRenderer(data: '', format: format)),
        );
        expect(find.byType(BarcodeWidget), findsNothing);
        expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      }
    });

    testWidgets('odd-length ITF shows the change-format state', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_host(BarcodeRenderer(
        data: '1234567',
        format: 'ITF',
        onChangeFormat: () => tapped = true,
      )));
      expect(find.byType(BarcodeWidget), findsNothing);
      await tester.tap(find.byType(TextButton));
      expect(tapped, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('valid value renders the barcode', (tester) async {
      await tester.pumpWidget(
        _host(const BarcodeRenderer(data: '4006381333931', format: 'EAN_13')),
      );
      expect(find.byType(BarcodeWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
