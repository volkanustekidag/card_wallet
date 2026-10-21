/// Folds text for accent- and case-insensitive search.
///
/// Turkish first: İ/I/ı/i all become `i`, and ş→s, ğ→g, ü→u, ö→o, ç→c, so
/// "İŞ BANKASI" and "is bankasi" or "Migros" and "mıgros" compare equal.
/// Common Latin accents from the other app languages (é, ä, ñ, ł, ß, ...)
/// fold the same way. Runs of whitespace collapse to one space.
///
/// Mapping happens before lower-casing so Dart's locale-free
/// `'İ'.toLowerCase()` (which yields `i̇`, an `i` plus a combining dot)
/// never reaches the result.
String normalizeForSearch(String input) {
  final out = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    final folded = _fold[ch];
    if (folded != null) {
      out.write(folded);
    } else if (rune == 0x0307) {
      // Stray combining dot above (e.g. a pre-lowercased "i̇"): drop it.
      continue;
    } else {
      out.write(ch.toLowerCase());
    }
  }
  return out.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

const Map<String, String> _fold = {
  // Turkish
  'İ': 'i', 'I': 'i', 'ı': 'i',
  'Ş': 's', 'ş': 's',
  'Ğ': 'g', 'ğ': 'g',
  'Ü': 'u', 'ü': 'u',
  'Ö': 'o', 'ö': 'o',
  'Ç': 'c', 'ç': 'c',
  // Other Latin accents (de, es, fr, it, nl, pl, pt)
  'À': 'a', 'Á': 'a', 'Â': 'a', 'Ã': 'a', 'Ä': 'a', 'Å': 'a', 'Ą': 'a',
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'ą': 'a',
  'È': 'e', 'É': 'e', 'Ê': 'e', 'Ë': 'e', 'Ę': 'e',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ę': 'e',
  'Ì': 'i', 'Í': 'i', 'Î': 'i', 'Ï': 'i',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
  'Ò': 'o', 'Ó': 'o', 'Ô': 'o', 'Õ': 'o', 'Ø': 'o',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ø': 'o',
  'Ù': 'u', 'Ú': 'u', 'Û': 'u',
  'ù': 'u', 'ú': 'u', 'û': 'u',
  'Ñ': 'n', 'ñ': 'n', 'Ń': 'n', 'ń': 'n',
  'Ć': 'c', 'ć': 'c',
  'Ł': 'l', 'ł': 'l',
  'Ś': 's', 'ś': 's',
  'Ź': 'z', 'ź': 'z', 'Ż': 'z', 'ż': 'z',
  'ß': 'ss',
};
