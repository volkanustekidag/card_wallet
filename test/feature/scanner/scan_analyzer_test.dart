import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/feature/scanner/scan_analyzer.dart';

void main() {
  group('barcodes', () {
    test('a retail barcode is a loyalty card', () {
      final hit = ScanAnalyzer.fromBarcode('3760012345670', 'EAN_13', ScanMode.auto);
      expect(hit, isA<LoyaltyHit>());
      expect((hit as LoyaltyHit).format, 'EAN_13');
    });

    test('EPC SEPA QR becomes an IBAN with name and BIC', () {
      const epc = 'BCD\n002\n1\nSCT\nBNPAFRPP\nAlex Morgan\n'
          'FR7630006000011234567890189\nEUR12.50\n\n\nInvoice';
      final hit = ScanAnalyzer.fromBarcode(epc, 'QR_CODE', ScanMode.auto);
      expect(hit, isA<IbanHit>());
      hit as IbanHit;
      expect(hit.iban, 'FR7630006000011234567890189');
      expect(hit.bic, 'BNPAFRPP');
      expect(hit.holder, 'Alex Morgan');
    });

    test('a QR holding a bare IBAN becomes an IBAN', () {
      final hit = ScanAnalyzer.fromBarcode(
          'DE89 3704 0044 0532 0130 00', 'QR_CODE', ScanMode.auto);
      expect((hit as IbanHit).iban, 'DE89370400440532013000');
    });

    test('barcode mode keeps an IBAN QR as a plain barcode', () {
      final hit = ScanAnalyzer.fromBarcode(
          'DE89370400440532013000', 'QR_CODE', ScanMode.barcode);
      expect(hit, isA<LoyaltyHit>());
    });

    test('card mode ignores barcodes', () {
      expect(ScanAnalyzer.fromBarcode('123', 'CODE_128', ScanMode.card), isNull);
    });
  });

  group('text', () {
    test('card number, expiry and name from OCR lines', () {
      const ocr = 'CHASE\n4242 4242 4242 4242\nVALID THRU 09/28\nALEX MORGAN';
      final hit = ScanAnalyzer.fromText(ocr, ScanMode.auto);
      expect(hit, isA<CardHit>());
      hit as CardHit;
      expect(hit.number, '4242424242424242');
      expect(hit.expiry, '09/28');
      expect(hit.holder, 'Alex Morgan');
    });

    test('a non-Luhn digit run is not a card', () {
      expect(ScanAnalyzer.cardFromText('4111 1111 1111 1112'), isNull);
    });

    test('IBAN from printed text, any country, grouped', () {
      final hit =
          ScanAnalyzer.fromText('IBAN: GB29 NWBK 6016 1331 9268 19', ScanMode.auto);
      expect((hit as IbanHit).iban, 'GB29NWBK60161331926819');
      expect(
        (ScanAnalyzer.fromText('TR33 0006 1005 1978 6457 8413 26', ScanMode.iban)
                as IbanHit)
            .iban,
        'TR330006100519786457841326',
      );
    });

    test('an IBAN with a bad checksum is rejected', () {
      expect(ScanAnalyzer.ibanFromText('DE88 3704 0044 0532 0130 00'), isNull);
    });

    test('barcode mode ignores text', () {
      expect(ScanAnalyzer.fromText('4111 1111 1111 4242', ScanMode.barcode),
          isNull);
    });
  });
}
