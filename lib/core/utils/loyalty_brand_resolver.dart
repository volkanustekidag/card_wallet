/// Maps loyalty-program brand names to their primary public domain.
/// Used by [BankLogo] (and friends) to fetch the brand's logo via the
/// Google favicon service. Lookup is case-insensitive — keys are
/// normalised to lowercase + stripped of common punctuation, so the
/// user can type "Starbucks", "STARBUCKS", or "starbucks" and still hit
/// the same row.
///
/// Coverage isn't exhaustive; it's the ~130 most common loyalty-card
/// brands a global user is likely to carry — coffee, fast food, grocery,
/// fashion, tech, fuel, hotel chains, airlines. Misses fall through to
/// the generic loyalty glyph.
class LoyaltyBrandResolver {
  static final Map<String, String> _brandDomain = {
    // ─── Coffee / cafés ──────────────────────────────────────────────
    'starbucks': 'starbucks.com',
    'costa coffee': 'costa.co.uk',
    'costa': 'costa.co.uk',
    'tim hortons': 'timhortons.com',
    'dunkin': 'dunkindonuts.com',
    'dunkin donuts': 'dunkindonuts.com',
    'peets coffee': 'peets.com',
    'peets': 'peets.com',
    'caffe nero': 'caffenero.com',
    'pret': 'pret.com',
    'pret a manger': 'pret.com',
    'tchibo': 'tchibo.com',
    'kahve dunyasi': 'kahvedunyasi.com',
    'mado': 'mado.com.tr',
    'espressolab': 'espressolab.com',
    'gloria jeans': 'gloriajeanscoffees.com',

    // ─── Fast food / QSR ─────────────────────────────────────────────
    'mcdonalds': 'mcdonalds.com',
    'burger king': 'burgerking.com',
    'kfc': 'kfc.com',
    'subway': 'subway.com',
    'pizza hut': 'pizzahut.com',
    'dominos': 'dominos.com',
    'dominos pizza': 'dominos.com',
    'papa johns': 'papajohns.com',
    'wendys': 'wendys.com',
    'chipotle': 'chipotle.com',
    'taco bell': 'tacobell.com',
    'five guys': 'fiveguys.com',
    'shake shack': 'shakeshack.com',
    'chick fil a': 'chick-fil-a.com',
    'in n out': 'in-n-out.com',
    'popeyes': 'popeyes.com',
    'sbarro': 'sbarro.com',

    // ─── Supermarket / grocery ───────────────────────────────────────
    'migros': 'migros.com.tr',
    'bim': 'bim.com.tr',
    'a101': 'a101.com.tr',
    'sok': 'sokmarket.com.tr',
    'sok market': 'sokmarket.com.tr',
    'sokmarket': 'sokmarket.com.tr',
    'carrefour': 'carrefour.com',
    'carrefoursa': 'carrefoursa.com',
    'macro center': 'macrocenter.com.tr',
    'tesco': 'tesco.com',
    'sainsburys': 'sainsburys.co.uk',
    'asda': 'asda.com',
    'waitrose': 'waitrose.com',
    'walmart': 'walmart.com',
    'costco': 'costco.com',
    'target': 'target.com',
    'kroger': 'kroger.com',
    'aldi': 'aldi.com',
    'lidl': 'lidl.com',
    'spar': 'spar-international.com',
    'auchan': 'auchan.com',
    'mercadona': 'mercadona.es',
    'edeka': 'edeka.de',
    'rewe': 'rewe.de',
    'penny': 'penny.de',

    // ─── Fashion / apparel ───────────────────────────────────────────
    'zara': 'zara.com',
    'h&m': 'hm.com',
    'hm': 'hm.com',
    'uniqlo': 'uniqlo.com',
    'bershka': 'bershka.com',
    'pull&bear': 'pullandbear.com',
    'pull and bear': 'pullandbear.com',
    'stradivarius': 'stradivarius.com',
    'mango': 'shop.mango.com',
    'massimo dutti': 'massimodutti.com',
    'gap': 'gap.com',
    'old navy': 'oldnavy.com',
    'banana republic': 'bananarepublic.com',
    'levis': 'levi.com',
    'levi strauss': 'levi.com',
    'nike': 'nike.com',
    'adidas': 'adidas.com',
    'puma': 'puma.com',
    'new balance': 'newbalance.com',
    'under armour': 'underarmour.com',
    'reebok': 'reebok.com',
    'tommy hilfiger': 'tommy.com',
    'calvin klein': 'calvinklein.com',
    'ralph lauren': 'ralphlauren.com',
    'lacoste': 'lacoste.com',
    'lc waikiki': 'lcwaikiki.com',
    'koton': 'koton.com',
    'defacto': 'defacto.com.tr',
    'mavi': 'mavi.com',
    'boyner': 'boyner.com.tr',

    // ─── Tech / electronics ──────────────────────────────────────────
    'apple': 'apple.com',
    'samsung': 'samsung.com',
    'microsoft': 'microsoft.com',
    'google': 'google.com',
    'best buy': 'bestbuy.com',
    'currys': 'currys.co.uk',
    'mediamarkt': 'mediamarkt.de',
    'media markt': 'mediamarkt.de',
    'vatan': 'vatanbilgisayar.com',
    'vatan bilgisayar': 'vatanbilgisayar.com',
    'teknosa': 'teknosa.com',

    // ─── E-commerce ──────────────────────────────────────────────────
    'amazon': 'amazon.com',
    'ebay': 'ebay.com',
    'aliexpress': 'aliexpress.com',
    'temu': 'temu.com',
    'shein': 'shein.com',
    'wayfair': 'wayfair.com',
    'etsy': 'etsy.com',
    'trendyol': 'trendyol.com',
    'hepsiburada': 'hepsiburada.com',
    'n11': 'n11.com',
    'asos': 'asos.com',

    // ─── Cosmetics / beauty / pharmacy ───────────────────────────────
    'sephora': 'sephora.com',
    'ulta': 'ulta.com',
    'watsons': 'watsons.com',
    'boots': 'boots.com',
    'the body shop': 'thebodyshop.com',
    'lush': 'lush.com',
    'mac cosmetics': 'maccosmetics.com',
    'mac': 'maccosmetics.com',
    'gratis': 'gratis.com',
    'cvs': 'cvs.com',
    'walgreens': 'walgreens.com',
    'dm': 'dm.de',
    'mueller': 'mueller.de',

    // ─── Home / department / sport ───────────────────────────────────
    'ikea': 'ikea.com',
    'bauhaus': 'bauhaus.de',
    'home depot': 'homedepot.com',
    'lowes': 'lowes.com',
    'decathlon': 'decathlon.com',
    'sports direct': 'sportsdirect.com',
    'foot locker': 'footlocker.com',
    'jd sports': 'jdsports.com',

    // ─── Fuel ────────────────────────────────────────────────────────
    'shell': 'shell.com',
    'bp': 'bp.com',
    'total': 'totalenergies.com',
    'totalenergies': 'totalenergies.com',
    'esso': 'esso.com',
    'mobil': 'mobil.com',
    'petrol ofisi': 'petrolofisi.com.tr',
    'opet': 'opet.com.tr',
    'aytemiz': 'aytemiz.com.tr',

    // ─── Hotels ──────────────────────────────────────────────────────
    'marriott': 'marriott.com',
    'hilton': 'hilton.com',
    'hyatt': 'hyatt.com',
    'ihg': 'ihg.com',
    'accor': 'accor.com',
    'best western': 'bestwestern.com',
    'wyndham': 'wyndhamhotels.com',
    'radisson': 'radissonhotels.com',
    'holiday inn': 'ihg.com',

    // ─── Airlines ────────────────────────────────────────────────────
    'turkish airlines': 'turkishairlines.com',
    'thy': 'turkishairlines.com',
    'miles and smiles': 'turkishairlines.com',
    'lufthansa': 'lufthansa.com',
    'klm': 'klm.com',
    'air france': 'airfrance.com',
    'british airways': 'britishairways.com',
    'american airlines': 'aa.com',
    'delta': 'delta.com',
    'united': 'united.com',
    'emirates': 'emirates.com',
    'qatar airways': 'qatarairways.com',
    'singapore airlines': 'singaporeair.com',

    // ─── Streaming / media / cinema ──────────────────────────────────
    'netflix': 'netflix.com',
    'spotify': 'spotify.com',
    'disney+': 'disneyplus.com',
    'disney plus': 'disneyplus.com',
    'cinemaximum': 'cinemaximum.com.tr',
    'mars sinemalari': 'marscinema.com.tr',
    'amc': 'amctheatres.com',
  };

  // Pre-compiled once. Building a RegExp is non-trivial; before this the
  // resolver re-built five of them per call, hit on every recent-card row
  // build and every carousel page swipe.
  static final RegExp _smartQuotes = RegExp(r'[’‘]');
  static final RegExp _strayPunct = RegExp(r"[\.,'`]");
  static final RegExp _whitespace = RegExp(r'\s+');

  // Sorted longest-first — used for the substring fallback. Computed once
  // because the previous code rebuilt + re-sorted this list on every call.
  static final List<String> _sortedKeys = _brandDomain.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  // Memoization caches. These are small (~hundreds of entries at the
  // upper bound) and keyed by user-supplied brand names so they don't
  // need cleanup. Without these, every recent-card row + every carousel
  // swipe re-ran the normalize+search pipeline.
  static final Map<String, String> _normalizeCache = <String, String>{};
  static final Map<String, String?> _domainCache = <String, String?>{};

  /// Normalises [brand] for lookup. Lowercase, trimmed, common punctuation
  /// (apostrophes, periods, commas, &) collapsed, multi-spaces flattened.
  static String _normalize(String brand) {
    final cached = _normalizeCache[brand];
    if (cached != null) return cached;
    final out = brand
        .toLowerCase()
        .replaceAll(_smartQuotes, '')
        .replaceAll(_strayPunct, '')
        .replaceAll(_whitespace, ' ')
        .trim();
    _normalizeCache[brand] = out;
    return out;
  }

  /// Returns the primary domain for a loyalty brand, or `null` if the
  /// brand isn't in the map.
  ///
  /// Lookup order:
  ///   1. Exact normalised key — fastest, covers "Starbucks", "STARBUCKS".
  ///   2. "and" → "&" variant — "h and m" → "h&m".
  ///   3. Substring match — the user typed extra words like
  ///      "Starbucks Coffee" or "My Migros", and one of our known brand
  ///      keys appears as a whole word inside it. Longest key wins so
  ///      "burger king" beats "burger" if both were in the map.
  static String? domainFor(String? brand) {
    if (brand == null || brand.isEmpty) return null;
    if (_domainCache.containsKey(brand)) return _domainCache[brand];
    final result = _resolve(brand);
    _domainCache[brand] = result;
    return result;
  }

  static String? _resolve(String brand) {
    final key = _normalize(brand);
    if (key.isEmpty) return null;

    // 1) Exact match.
    final hit = _brandDomain[key];
    if (hit != null) return hit;

    // 2) and↔& variant.
    final altAnd = key.replaceAll(' and ', '&');
    final altHit = _brandDomain[altAnd];
    if (altHit != null) return altHit;

    // 3) Word-boundary substring match — handles "Starbucks Coffee",
    // "My Migros", etc. Sorted longest-first so multi-word keys
    // ("burger king") win over their constituent words.
    final padded = ' $key ';
    for (final k in _sortedKeys) {
      if (padded.contains(' $k ')) return _brandDomain[k];
    }
    return null;
  }
}
