import 'package:wallet_app/core/brands/brand_catalog.dart';
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_scanner_service.dart';
import 'package:wallet_app/core/utils/card_number_layout.dart';
import 'package:wallet_app/core/utils/validators.dart';

/// What the scanner is looking for. [auto] accepts the first confident hit
/// of any kind.
enum ScanMode { auto, card, barcode, iban }

sealed class ScanHit {
  const ScanHit();

  /// Same physical thing as [other] (used to require two matching frames).
  bool sameAs(ScanHit other);
}

class LoyaltyHit extends ScanHit {
  final String raw;
  final String format;

  /// Brand read from the card's printed text, when it named a known one.
  final BrandEntry? brand;
  const LoyaltyHit(this.raw, this.format, {this.brand});

  LoyaltyHit withBrand(BrandEntry? b) => LoyaltyHit(raw, format, brand: b);

  @override
  bool sameAs(ScanHit other) =>
      other is LoyaltyHit && other.raw == raw && other.format == format;
}

class CardHit extends ScanHit {
  /// Digits only.
  final String number;

  /// MM/YY or null.
  final String? expiry;
  final String? holder;
  const CardHit(this.number, {this.expiry, this.holder});

  @override
  bool sameAs(ScanHit other) => other is CardHit && other.number == number;
}

class IbanHit extends ScanHit {
  /// Upper case, no spaces.
  final String iban;
  final String? holder;
  final String? bic;
  const IbanHit(this.iban, {this.holder, this.bic});

  @override
  bool sameAs(ScanHit other) => other is IbanHit && other.iban == iban;
}

/// Turns raw scanner output (barcode payloads, OCR text) into wallet items.
/// Pure Dart so every rule is unit-tested.
abstract final class ScanAnalyzer {
  static final RegExp _ibanCandidate =
      RegExp(r'\b[A-Z]{2}\d{2}(?:[ ]?[A-Z0-9]{2,4}){3,9}\b');

  /// A barcode payload: SEPA/EPC transfer QRs and bare IBAN QRs become an
  /// IBAN, everything else is a loyalty barcode.
  static ScanHit? fromBarcode(String raw, String? format, ScanMode mode) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    if (mode != ScanMode.barcode) {
      final iban = ibanFromPayload(value);
      if (iban != null) return iban;
    }
    if (mode == ScanMode.iban || mode == ScanMode.card) return null;
    if (format == null) return null;
    return LoyaltyHit(value, format);
  }

  /// EPC069-12 ("BCD" SEPA credit transfer) or a payload that is / holds a
  /// valid IBAN.
  static IbanHit? ibanFromPayload(String payload) {
    final lines = payload.split(RegExp(r'\r?\n'));
    if (lines.length >= 7 && lines[0].trim() == 'BCD') {
      final iban = _clean(lines[6]);
      if (IbanValidator.isValid(iban)) {
        final bic = lines[4].trim();
        final name = lines[5].trim();
        return IbanHit(
          iban,
          bic: bic.isEmpty ? null : bic.toUpperCase(),
          holder: name.isEmpty ? null : name,
        );
      }
    }
    final whole = _clean(payload);
    if (whole.length <= 34 && IbanValidator.isValid(whole)) {
      return IbanHit(whole);
    }
    return ibanFromText(payload.toUpperCase());
  }

  /// First checksum-valid IBAN in OCR text (spaces allowed between groups).
  static IbanHit? ibanFromText(String text) {
    for (final line in text.toUpperCase().split('\n')) {
      for (final m in _ibanCandidate.allMatches(line)) {
        var candidate = _clean(m.group(0)!);
        // OCR runs the next word in; shrink from the right until valid.
        while (candidate.length >= 15) {
          if (IbanValidator.isValid(candidate)) return IbanHit(candidate);
          candidate = candidate.substring(0, candidate.length - 1);
        }
      }
    }
    return null;
  }

  /// A Luhn-valid card number plus expiry and name when OCR found them.
  static CardHit? cardFromText(String text) {
    final number = CreditCardScannerService.extractCardNumber(text);
    if (number == null) return null;
    final info = CreditCardScannerService.parseCardText(text);
    final expiry = info['expiryDate'];
    final holder = info['cardHolder'];
    return CardHit(
      CardNumberLayout.digitsOf(number),
      expiry: (expiry == null || expiry.isEmpty) ? null : expiry,
      holder: (holder == null || holder.isEmpty) ? null : holder,
    );
  }

  /// OCR text in [mode]: a card number wins over an IBAN in auto mode.
  static ScanHit? fromText(String text, ScanMode mode) {
    if (mode == ScanMode.barcode) return null;
    if (mode != ScanMode.iban) {
      final card = cardFromText(text);
      if (card != null) return card;
    }
    if (mode != ScanMode.card) return ibanFromText(text);
    return null;
  }

  static String _clean(String s) =>
      s.replaceAll(RegExp(r'[\s\-]'), '').toUpperCase();
}
