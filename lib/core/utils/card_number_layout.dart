/// Digit grouping and length rules for card numbers, keyed on the IIN
/// (leading digits).
///
///   * American Express (34, 37): 15 digits, 4-6-5
///   * Diners Club International (36): 14 digits, 4-6-4
///   * Diners Club (300-305, 309, 38, 39): 14 digits 4-6-4, or 16 digits
///     4-4-4-4 for the Mastercard co-branded ranges
///   * Everything else: up to 19 digits in groups of four (Visa 13/16/19,
///     Mastercard 16, UnionPay/Maestro 16-19…)
class CardNumberLayout {
  const CardNumberLayout._();

  static const int minDigits = 13;
  static const int maxDigits = 19;

  static String digitsOf(String raw) => raw.replaceAll(RegExp(r'\D'), '');

  static bool _isAmex(String d) => d.startsWith('34') || d.startsWith('37');

  static bool _isDiners14(String d) => d.startsWith('36');

  static bool _isDinersFlexible(String d) {
    if (d.startsWith('38') || d.startsWith('39')) return true;
    if (d.length < 3) return d == '30';
    final first3 = int.parse(d.substring(0, 3));
    return (first3 >= 300 && first3 <= 305) || first3 == 309;
  }

  /// Longest number the IIN allows.
  static int maxDigitsFor(String raw) {
    final d = digitsOf(raw);
    if (_isAmex(d)) return 15;
    if (_isDiners14(d)) return 14;
    if (_isDinersFlexible(d)) return 16;
    return maxDigits;
  }

  /// Group sizes for the number as typed so far.
  static List<int> groupsFor(String raw) {
    final d = digitsOf(raw);
    if (_isAmex(d)) return const [4, 6, 5];
    if (_isDiners14(d)) return const [4, 6, 4];
    if (_isDinersFlexible(d) && d.length <= 14) return const [4, 6, 4];
    return const [4, 4, 4, 4, 3];
  }

  /// Valid stored length: 13-19 digits and within the IIN's maximum.
  static bool isValidLength(String raw) {
    final d = digitsOf(raw);
    if (d.length < minDigits || d.length > maxDigitsFor(d)) return false;
    if (_isAmex(d)) return d.length == 15;
    if (_isDiners14(d)) return d.length == 14;
    if (_isDinersFlexible(d)) return d.length == 14 || d.length == 16;
    return true;
  }

  /// Digits capped at [maxDigitsFor] and grouped with single spaces.
  static String format(String raw) {
    var d = digitsOf(raw);
    final max = maxDigitsFor(d);
    if (d.length > max) d = d.substring(0, max);
    return _group(d, groupsFor(d));
  }

  /// Same grouping as [format] with every digit but the last four replaced
  /// by [bullet].
  static String mask(String raw, {String bullet = '•'}) {
    final d = digitsOf(raw);
    if (d.length <= 4) return d;
    final masked = bullet * (d.length - 4) + d.substring(d.length - 4);
    return _group(masked, groupsFor(d));
  }

  static String _group(String chars, List<int> groups) {
    final buffer = StringBuffer();
    var index = 0;
    for (var g = 0; g < groups.length && index < chars.length; g++) {
      if (g > 0) buffer.write(' ');
      final end = (index + groups[g]).clamp(0, chars.length);
      buffer.write(chars.substring(index, end));
      index = end;
    }
    // Anything past the last group (shouldn't happen once capped).
    if (index < chars.length) buffer.write(' ${chars.substring(index)}');
    return buffer.toString();
  }
}
