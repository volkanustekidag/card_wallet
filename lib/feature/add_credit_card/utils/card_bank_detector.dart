class CardBankDetector {
  static final Map<String, String> _binToBank = {
    '454360': 'Garanti BBVA',
    '454363': 'Garanti BBVA',
    '450803': 'Garanti BBVA',
    '552608': 'Akbank',
    '979202': 'Ziraat Bankası',
    '979203': 'Ziraat Bankası',
    '402277': 'Yapı Kredi',
    '415565': 'Türkiye İş Bankası',
    '979244': 'VakifBank',
    '979206': 'Halkbank',
    '979212': 'QNB Finansbank',
    '533923': 'DenizBank',
    '552879': 'HSBC',
    '510153': 'TEB',
    '493824': 'Kuveyt Türk',
    '979287': 'ING Bank',
    '979289': 'Odeabank',
  };

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
}
