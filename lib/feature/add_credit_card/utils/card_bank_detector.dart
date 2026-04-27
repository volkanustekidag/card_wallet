/// Network identifiers used by [CardBankDetector.networkFor].
enum CardNetwork { visa, mastercard, amex, discover, dinersClub, jcb, unknown }

class CardBankDetector {
  // Curated TR-focused BIN → bank table. Longest prefix wins.
  static final Map<String, String> _binToBank = {
    // Garanti BBVA
    '454360': 'Garanti BBVA',
    '454363': 'Garanti BBVA',
    '450803': 'Garanti BBVA',
    '450803': 'Garanti BBVA',
    '4546': 'Garanti BBVA',
    // Akbank
    '552608': 'Akbank',
    '435508': 'Akbank',
    '4022': 'Akbank',
    // Ziraat
    '979202': 'Ziraat Bankası',
    '979203': 'Ziraat Bankası',
    '454671': 'Ziraat Bankası',
    // Yapı Kredi
    '402277': 'Yapı Kredi',
    '492181': 'Yapı Kredi',
    '454368': 'Yapı Kredi',
    // İş Bankası
    '415565': 'Türkiye İş Bankası',
    '454545': 'Türkiye İş Bankası',
    '5582': 'Türkiye İş Bankası',
    // VakifBank
    '979244': 'VakıfBank',
    '4256': 'VakıfBank',
    // Halkbank
    '979206': 'Halkbank',
    '5489': 'Halkbank',
    // QNB Finansbank
    '979212': 'QNB Finansbank',
    '6501': 'QNB Finansbank',
    // DenizBank
    '533923': 'DenizBank',
    '434141': 'DenizBank',
    // HSBC
    '552879': 'HSBC',
    // TEB
    '510153': 'TEB',
    // Kuveyt Türk
    '493824': 'Kuveyt Türk',
    // ING
    '979287': 'ING Bank',
    // Odea
    '979289': 'Odeabank',
    // Türk Ekonomi Bankası alt prefix
    '5285': 'TEB',
    // Anadolu Bank
    '4011': 'Anadolu Bank',
    // Şekerbank
    '4022': 'Şekerbank',
    // Albaraka Türk
    '5491': 'Albaraka Türk',
  };

  /// Detects the issuing bank from a partial or full card number. Returns
  /// `null` if no prefix matches.
  static String? detect(String cardNumber) {
    final sanitized = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (sanitized.length < 4) return null;

    final sortedKeys = _binToBank.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final key in sortedKeys) {
      if (sanitized.startsWith(key)) {
        return _binToBank[key];
      }
    }
    return null;
  }

  /// Detects the card network from the leading digits. Spec follows the
  /// public IIN ranges; intentionally permissive so partial input works.
  static CardNetwork networkFor(String cardNumber) {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return CardNetwork.unknown;

    // Visa: 4
    if (digits.startsWith('4')) return CardNetwork.visa;

    // Mastercard: 51-55, 2221-2720
    if (digits.length >= 2) {
      final first2 = int.parse(digits.substring(0, 2));
      if (first2 >= 51 && first2 <= 55) return CardNetwork.mastercard;
    }
    if (digits.length >= 4) {
      final first4 = int.parse(digits.substring(0, 4));
      if (first4 >= 2221 && first4 <= 2720) return CardNetwork.mastercard;
    }

    // Amex: 34, 37
    if (digits.startsWith('34') || digits.startsWith('37')) {
      return CardNetwork.amex;
    }

    // Discover: 6011, 644-649, 65
    if (digits.startsWith('6011') || digits.startsWith('65')) {
      return CardNetwork.discover;
    }
    if (digits.length >= 3) {
      final first3 = int.parse(digits.substring(0, 3));
      if (first3 >= 644 && first3 <= 649) return CardNetwork.discover;
    }

    // Diners: 300-305, 36, 38
    if (digits.startsWith('36') || digits.startsWith('38')) {
      return CardNetwork.dinersClub;
    }
    if (digits.length >= 3) {
      final first3 = int.parse(digits.substring(0, 3));
      if (first3 >= 300 && first3 <= 305) return CardNetwork.dinersClub;
    }

    // JCB: 3528-3589
    if (digits.length >= 4) {
      final first4 = int.parse(digits.substring(0, 4));
      if (first4 >= 3528 && first4 <= 3589) return CardNetwork.jcb;
    }

    return CardNetwork.unknown;
  }
}
