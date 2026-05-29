/// Lightweight, dependency-free validation helpers used by add-card flows.
class CardValidators {
  /// Luhn checksum for credit/debit card numbers. Returns true if the number
  /// has a valid check digit. Whitespace is ignored. Length must be 13-19.
  static bool isValidLuhn(String number) {
    final digits = number.replaceAll(RegExp(r'\s+'), '');
    if (digits.length < 13 || digits.length > 19) return false;
    if (!RegExp(r'^\d+$').hasMatch(digits)) return false;

    var sum = 0;
    var alternate = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var n = digits.codeUnitAt(i) - 0x30;
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  /// Expiration validator. Accepts MM/YY or MM / YY formats.
  /// Month must be 1-12; year (20YY) must be >= current year; combined
  /// month/year must not be in the past.
  static bool isValidExpiration(String mmYy) {
    final cleaned = mmYy.replaceAll(' ', '');
    final match = RegExp(r'^(\d{2})\/(\d{2})$').firstMatch(cleaned);
    if (match == null) return false;
    final month = int.parse(match.group(1)!);
    final year = 2000 + int.parse(match.group(2)!);
    if (month < 1 || month > 12) return false;
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(year, month + 1, 0);
    return !lastDayOfMonth.isBefore(DateTime(now.year, now.month, 1));
  }
}

class IbanValidator {
  /// IBAN validation per ISO 13616 (mod 97 = 1) plus per-country length check.
  /// Whitespace is ignored. Returns true for syntactically valid IBANs.
  static bool isValid(String iban) {
    final cleaned = iban.replaceAll(' ', '').toUpperCase();
    if (cleaned.length < 15 || cleaned.length > 34) return false;
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(cleaned)) return false;

    final countryCode = cleaned.substring(0, 2);
    final expectedLength = _countryLengths[countryCode];
    if (expectedLength != null && cleaned.length != expectedLength) {
      return false;
    }

    // Move first 4 chars to end, then convert letters to digits (A=10..Z=35).
    final rearranged = cleaned.substring(4) + cleaned.substring(0, 4);
    final buffer = StringBuffer();
    for (final ch in rearranged.codeUnits) {
      if (ch >= 0x30 && ch <= 0x39) {
        buffer.writeCharCode(ch);
      } else if (ch >= 0x41 && ch <= 0x5A) {
        buffer.write(ch - 0x41 + 10);
      } else {
        return false;
      }
    }

    // Compute mod 97 over a potentially huge integer string in chunks.
    final numeric = buffer.toString();
    var remainder = 0;
    for (var i = 0; i < numeric.length; i += 7) {
      final end = (i + 7 < numeric.length) ? i + 7 : numeric.length;
      final chunk = remainder.toString() + numeric.substring(i, end);
      remainder = int.parse(chunk) % 97;
    }
    return remainder == 1;
  }

  static const Map<String, int> _countryLengths = {
    'AD': 24, 'AE': 23, 'AL': 28, 'AT': 20, 'AZ': 28, 'BA': 20, 'BE': 16,
    'BG': 22, 'BH': 22, 'BR': 29, 'BY': 28, 'CH': 21, 'CR': 22, 'CY': 28,
    'CZ': 24, 'DE': 22, 'DK': 18, 'DO': 28, 'EE': 20, 'EG': 29, 'ES': 24,
    'FI': 18, 'FO': 18, 'FR': 27, 'GB': 22, 'GE': 22, 'GI': 23, 'GL': 18,
    'GR': 27, 'GT': 28, 'HR': 21, 'HU': 28, 'IE': 22, 'IL': 23, 'IQ': 23,
    'IS': 26, 'IT': 27, 'JO': 30, 'KW': 30, 'KZ': 20, 'LB': 28, 'LC': 32,
    'LI': 21, 'LT': 20, 'LU': 20, 'LV': 21, 'MC': 27, 'MD': 24, 'ME': 22,
    'MK': 19, 'MR': 27, 'MT': 31, 'MU': 30, 'NL': 18, 'NO': 15, 'PK': 24,
    'PL': 28, 'PS': 29, 'PT': 25, 'QA': 29, 'RO': 24, 'RS': 22, 'SA': 24,
    'SC': 31, 'SE': 24, 'SI': 19, 'SK': 24, 'SM': 27, 'ST': 25, 'SV': 28,
    'TL': 23, 'TN': 24, 'TR': 26, 'UA': 29, 'VA': 22, 'VG': 24, 'XK': 20,
  };
}
