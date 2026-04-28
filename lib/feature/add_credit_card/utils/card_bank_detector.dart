/// Card payment networks identified by [CardBankDetector.networkFor].
enum CardNetwork { visa, mastercard, amex, discover, dinersClub, jcb, unknown }

/// Best-effort BIN → bank lookup. Longest matching prefix wins, so 6-digit
/// BINs override 4-digit ones. Coverage is curated, not exhaustive — banks
/// share BIN blocks and individual ranges shift over time, so an unknown
/// result simply means "we don't know this BIN" rather than "invalid card".
class CardBankDetector {
  static final Map<String, String> _binToBank = {
    // ─── United States ────────────────────────────────────────────────
    '414709': 'Chase',
    '414720': 'Chase',
    '426684': 'Chase',
    '447754': 'Chase',
    '481583': 'Chase',
    '4266': 'Chase',
    '4477': 'Chase',
    '5424': 'Chase',
    '474449': 'Bank of America',
    '477232': 'Bank of America',
    '481477': 'Bank of America',
    '4744': 'Bank of America',
    '4772': 'Bank of America',
    '412317': 'Citibank',
    '423199': 'Citibank',
    '4128': 'Citibank',
    '5466': 'Citibank',
    '414676': 'Wells Fargo',
    '4146': 'Wells Fargo',
    '405560': 'Capital One',
    '413773': 'Capital One',
    '518916': 'Capital One',
    '4055': 'Capital One',
    '5189': 'Capital One',
    '601100': 'Discover',
    '650580': 'Discover',
    '6011': 'Discover',
    '6500': 'Discover',
    '378282': 'American Express',
    '371449': 'American Express',
    '3782': 'American Express',
    '3714': 'American Express',
    '510510': 'US Bank',
    '5105': 'US Bank',
    '432048': 'PNC Bank',
    '4320': 'PNC Bank',

    // ─── United Kingdom ───────────────────────────────────────────────
    '492944': 'Barclays',
    '475148': 'Barclays',
    '4929': 'Barclays',
    '446229': 'HSBC UK',
    '454128': 'HSBC UK',
    '4541': 'HSBC UK',
    '465901': 'Lloyds Bank',
    '4659': 'Lloyds Bank',
    '467200': 'NatWest',
    '4672': 'NatWest',
    '454313': 'Santander UK',
    '5301': 'Santander UK',
    '489470': 'Revolut',
    '535811': 'Revolut',
    '4894': 'Revolut',
    '519333': 'Monzo',
    '5193': 'Monzo',
    '402942': 'Starling Bank',
    '4029': 'Starling Bank',

    // ─── Germany / Austria / Switzerland ──────────────────────────────
    '414740': 'Deutsche Bank',
    '517045': 'Deutsche Bank',
    '405300': 'Commerzbank',
    '4053': 'Commerzbank',
    '5170': 'Commerzbank',
    '521234': 'Sparkasse',
    '5286': 'Sparkasse',
    '534573': 'N26',
    '456127': 'N26',
    '5345': 'N26',

    // ─── France / Benelux ─────────────────────────────────────────────
    '497247': 'BNP Paribas',
    '517440': 'BNP Paribas',
    '4972': 'BNP Paribas',
    '497747': 'Société Générale',
    '4977': 'Société Générale',
    '498747': 'Crédit Agricole',
    '4987': 'Crédit Agricole',
    '531855': 'ING',
    '545454': 'ING',
    '5318': 'ING',
    '493737': 'Rabobank',
    '4937': 'Rabobank',

    // ─── Spain / Italy ────────────────────────────────────────────────
    '454617': 'Santander',
    '4546': 'Santander',
    '454618': 'BBVA',
    '4548': 'BBVA',
    '454619': 'CaixaBank',
    '454620': 'UniCredit',
    '4530': 'UniCredit',
    '492181': 'Intesa Sanpaolo',

    // ─── Fintechs / Multi-country ─────────────────────────────────────
    '535419': 'Wise',
    '5354': 'Wise',
    '481791': 'Wise',
    '4124': 'Wise',
    '536846': 'Curve',
    '5368': 'Curve',

    // ─── Asia / Pacific ───────────────────────────────────────────────
    '412342': 'DBS Bank',
    '4123': 'DBS Bank',
    '450993': 'Standard Chartered',
    '4509': 'Standard Chartered',
    '454004': 'HSBC Asia',
    '4540': 'HSBC Asia',
    '5419': 'HSBC Asia',

    // ─── Türkiye ──────────────────────────────────────────────────────
    '454360': 'Garanti BBVA',
    '454363': 'Garanti BBVA',
    '450803': 'Garanti BBVA',
    '454671': 'Ziraat Bankası',
    '979202': 'Ziraat Bankası',
    '979203': 'Ziraat Bankası',
    '402277': 'Yapı Kredi',
    '454368': 'Yapı Kredi',
    '415565': 'Türkiye İş Bankası',
    '454545': 'Türkiye İş Bankası',
    '5582': 'Türkiye İş Bankası',
    '979244': 'VakıfBank',
    '4256': 'VakıfBank',
    '979206': 'Halkbank',
    '5489': 'Halkbank',
    '979212': 'QNB Finansbank',
    '6501': 'QNB Finansbank',
    '533923': 'DenizBank',
    '434141': 'DenizBank',
    '552879': 'HSBC TR',
    '510153': 'TEB',
    '5285': 'TEB',
    '493824': 'Kuveyt Türk',
    '979287': 'ING TR',
    '979289': 'Odeabank',
    '4011': 'Anadolu Bank',
    '4172': 'Şekerbank',
    '5491': 'Albaraka Türk',
    '552608': 'Akbank',
    '435508': 'Akbank',
    '4358': 'Akbank',
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
