import 'package:barcode_widget/barcode_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/feature/loyalty_card/loyalty_barcode_formats.dart';

/// Why a loyalty barcode value can't be shown in its format.
enum BarcodeIssue {
  empty,

  /// EAN/UPC/ITF value contains something other than digits.
  digitsOnly,

  /// Wrong digit count for a fixed-length format ([BarcodeCheck.expectedLength]).
  length,

  /// ITF encodes digit pairs.
  evenLength,

  /// Last digit isn't the GTIN mod-10 check digit of the others.
  checkDigit,

  /// Passes the rules above but the encoder still rejects it (UPC-E number
  /// system, Code 39 lowercase, …).
  notEncodable,
}

class BarcodeCheck {
  final BarcodeIssue? issue;
  final int? expectedLength;

  const BarcodeCheck._(this.issue, [this.expectedLength]);

  static const valid = BarcodeCheck._(null);

  bool get isValid => issue == null;
}

/// Validates loyalty barcodes before they are saved and before they reach
/// [BarcodeWidget]. The widget's own `verify` misses cases that only fail
/// while painting (odd-length ITF), and painting errors are reported as
/// FlutterErrors — the `BarcodeException` events in Crashlytics.
abstract final class LoyaltyBarcodeValidator {
  static const Map<String, int> _fixedLengths = {
    'EAN_13': 13,
    'EAN_8': 8,
    'UPC_A': 12,
    'UPC_E': 8,
  };

  static final RegExp _digits = RegExp(r'^\d+$');

  /// Order in which [suggestFormat] tries alternatives: the most specific
  /// retail formats first, then the general-purpose ones.
  static const List<String> _suggestionOrder = [
    'EAN_13',
    'EAN_8',
    'UPC_A',
    'UPC_E',
    'CODE_128',
    'QR_CODE',
  ];

  static BarcodeCheck validate(String value, String format) {
    final data = value.trim();
    if (data.isEmpty) return const BarcodeCheck._(BarcodeIssue.empty);

    final fixed = _fixedLengths[format];
    if (fixed != null || format == 'ITF') {
      if (!_digits.hasMatch(data)) {
        return const BarcodeCheck._(BarcodeIssue.digitsOnly);
      }
      if (fixed != null && data.length != fixed) {
        return BarcodeCheck._(BarcodeIssue.length, fixed);
      }
      if (format == 'UPC_E' && data[0] != '0' && data[0] != '1') {
        // Only number systems 0 and 1 have a UPC-E form.
        return const BarcodeCheck._(BarcodeIssue.notEncodable);
      }
      if (format == 'ITF' && data.length.isOdd) {
        return const BarcodeCheck._(BarcodeIssue.evenLength);
      }
      if (fixed != null && !_hasValidCheckDigit(data, format)) {
        return const BarcodeCheck._(BarcodeIssue.checkDigit);
      }
    }

    if (!canEncode(data, format)) {
      return const BarcodeCheck._(BarcodeIssue.notEncodable);
    }
    return BarcodeCheck.valid;
  }

  /// A format other than [current] that can show [value], or null when
  /// the value is empty.
  static String? suggestFormat(String value, String current) {
    final data = value.trim();
    if (data.isEmpty) return null;
    for (final format in _suggestionOrder) {
      if (format != current && validate(data, format).isValid) return format;
    }
    return null;
  }

  /// Dry-runs the encoder [BarcodeWidget] paints with. True when the
  /// value renders without throwing.
  static bool canEncode(String value, String format) {
    if (value.isEmpty) return false;
    if (format == 'QR_CODE') return true;
    final barcode = barcodeFor(format);
    if (barcode == null) return false;
    try {
      barcode.verify(value);
      barcode.make(value, width: 200, height: 80, drawText: false).toList();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// The encoder for a stored format name; null for QR_CODE and unknown.
  static Barcode? barcodeFor(String format) {
    switch (format) {
      case 'CODE_128':
        return Barcode.code128();
      case 'CODE_39':
        return Barcode.code39();
      case 'EAN_13':
        return Barcode.ean13();
      case 'EAN_8':
        return Barcode.ean8();
      case 'UPC_A':
        return Barcode.upcA();
      case 'UPC_E':
        return Barcode.upcE();
      case 'ITF':
        return Barcode.itf();
      default:
        return null;
    }
  }

  static bool _hasValidCheckDigit(String data, String format) {
    final body = format == 'UPC_E' ? _expandUpcE(data) : data;
    final check = int.parse(data[data.length - 1]);
    return gtinCheckDigit(body.substring(0, body.length - 1)) == check;
  }

  /// GTIN mod-10: weights 3,1,3,… from the rightmost data digit.
  static int gtinCheckDigit(String digits) {
    var sum = 0;
    for (var i = 0; i < digits.length; i++) {
      final d = digits.codeUnitAt(digits.length - 1 - i) - 0x30;
      sum += i.isEven ? d * 3 : d;
    }
    return (10 - sum % 10) % 10;
  }

  /// 8-digit UPC-E (number system, 6 digits, check) to its 12-digit UPC-A
  /// form; the check digit is defined on the UPC-A form.
  static String _expandUpcE(String upce) {
    final ns = upce[0];
    final d = upce.substring(1, 7);
    final check = upce[7];
    final String manufacturerProduct;
    switch (d[5]) {
      case '0':
      case '1':
      case '2':
        manufacturerProduct =
            '${d.substring(0, 2)}${d[5]}0000${d.substring(2, 5)}';
        break;
      case '3':
        manufacturerProduct = '${d.substring(0, 3)}00000${d.substring(3, 5)}';
        break;
      case '4':
        manufacturerProduct = '${d.substring(0, 4)}00000${d[4]}';
        break;
      default:
        manufacturerProduct = '${d.substring(0, 5)}0000${d[5]}';
    }
    return '$ns$manufacturerProduct$check';
  }
}

/// Inline field error / dialog reason for [check]; null when valid or empty
/// (the required-field marker covers empty).
String? describeBarcodeIssue(BarcodeCheck check, String format) {
  switch (check.issue) {
    case null:
    case BarcodeIssue.empty:
      return null;
    case BarcodeIssue.digitsOnly:
      return 'loyaltyBarcodeDigitsOnlyError'.tr();
    case BarcodeIssue.length:
      return 'loyaltyBarcodeLengthError'.tr(
        namedArgs: {'count': '${check.expectedLength}'},
      );
    case BarcodeIssue.evenLength:
      return 'loyaltyBarcodeEvenLengthError'.tr();
    case BarcodeIssue.checkDigit:
      return 'loyaltyBarcodeCheckDigitError'.tr();
    case BarcodeIssue.notEncodable:
      return 'loyaltyBarcodeNotEncodableError'.tr(
        namedArgs: {'format': barcodeFormatLabel(format)},
      );
  }
}
