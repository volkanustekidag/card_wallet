import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:wallet_app/core/brands/brand_region.dart';
import 'package:wallet_app/core/services/ui_prefs.dart';
import 'package:wallet_app/core/utils/search_normalize.dart';

/// One loyalty programme / merchant from `assets/brands/brands.json`.
class BrandEntry {
  final String name;

  /// Website used to fetch the logo (favicon service), no scheme.
  final String domain;

  /// ARGB brand colour for the card face.
  final int color;
  final List<String> regions;
  final List<String> aliases;
  final String kind;

  /// 1 = a household name in its countries, 2 = major, 3 = regional.
  /// Orders the list shown before the user types.
  final int tier;

  BrandEntry({
    required this.name,
    required this.domain,
    required this.color,
    required this.regions,
    this.aliases = const [],
    this.kind = '',
    this.tier = 2,
  });

  factory BrandEntry.fromJson(Map<String, dynamic> j) => BrandEntry(
        name: j['n'] as String,
        domain: j['d'] as String,
        color:
            0xFF000000 | int.parse((j['c'] as String).substring(1), radix: 16),
        regions: [
          for (final r in (j['r'] as List).cast<String>()) normalizeCountry(r)!
        ],
        aliases: ((j['a'] as List?) ?? const []).cast<String>(),
        kind: (j['k'] as String?) ?? '',
        tier: (j['p'] as int?) ?? 2,
      );

  /// Every searchable spelling, normalised.
  late final List<String> keys = [
    normalizeForSearch(name),
    // "盒马 Freshippo" → also "freshippo"; "Migros" stays "migros".
    ...name.split(' ').length > 1 && name.runes.any((r) => r > 0x2E80)
        ? [normalizeForSearch(name.split(' ').skip(1).join(' '))]
        : const <String>[],
    for (final a in aliases) normalizeForSearch(a),
  ];

  bool inRegion(String? country) =>
      regions.contains('global') ||
      (country != null && regions.contains(normalizeCountry(country)));
}

/// Global catalogue of loyalty brands (all regions, incl. CJK names).
/// Loaded once in the background at startup; until then lookups simply
/// return nothing and the app falls back to what the user typed.
///
/// Local brands rank first. "Local" is the country the user picked in the
/// brand picker, else the one their time zone points to, else the one in
/// the phone's locale.
class BrandCatalog {
  BrandCatalog._();
  static final BrandCatalog instance = BrandCatalog._();

  List<BrandEntry> _all = const [];
  Future<void>? _loading;
  String? _zoneCountry;

  bool get isLoaded => _all.isNotEmpty;
  List<BrandEntry> get all => _all;

  /// Country ("it", "gb", …) whose brands rank first.
  String? get country =>
      normalizeCountry(UiPrefs.instance.brandCountry.value) ?? detectedCountry;

  /// Best guess without the user's pick: time zone, then locale.
  String? get detectedCountry =>
      _zoneCountry ??
      normalizeCountry(ui.PlatformDispatcher.instance.locale.countryCode);

  /// Countries with brands of their own, for the country picker.
  List<String> get countries {
    final out = {
      for (final e in _all)
        for (final r in e.regions)
          if (r != 'global') r,
    }.toList()
      ..sort();
    return out;
  }

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      _zoneCountry = countryForTimezone(zone.identifier);
    } catch (_) {
      // No plugin (tests) or no zone: the locale decides.
    }
    try {
      final raw = await rootBundle.loadString('assets/brands/brands.json');
      _all = await compute(_parse, raw);
    } catch (e) {
      debugPrint('Brand catalogue failed to load: $e');
      _loading = null;
    }
  }

  static List<BrandEntry> _parse(String raw) => [
        for (final j in jsonDecode(raw) as List)
          BrandEntry.fromJson(j as Map<String, dynamic>),
      ];

  @visibleForTesting
  void debugSetEntries(List<BrandEntry> entries) => _all = entries;

  @visibleForTesting
  set debugZoneCountry(String? c) => _zoneCountry = c;

  /// The brand [text] names: exact name/alias first, then a known brand
  /// appearing as whole words inside it ("My Starbucks card"). Local and
  /// global entries win over other regions' namesakes.
  BrandEntry? match(String? text) {
    if (text == null || _all.isEmpty) return null;
    final q = normalizeForSearch(text);
    if (q.isEmpty) return null;
    BrandEntry? best;
    var bestScore = 0;
    final padded = ' $q ';
    for (final e in _all) {
      for (final k in e.keys) {
        if (k.isEmpty) continue;
        int score;
        if (k == q) {
          score = 1000;
        } else if (k.length >= 3 && padded.contains(' $k ')) {
          score = 100 + k.length;
        } else {
          continue;
        }
        if (e.inRegion(country)) score += 50;
        if (score > bestScore) {
          bestScore = score;
          best = e;
        }
      }
    }
    return best;
  }

  /// Type-ahead results for the brand picker.
  List<BrandEntry> search(String query, {int limit = 30}) {
    final q = normalizeForSearch(query);
    final c = country;
    if (q.isEmpty) return popular(limit: limit);
    final scored = <(BrandEntry, int)>[];
    for (final e in _all) {
      var s = 0;
      for (final k in e.keys) {
        if (k.startsWith(q)) {
          s = s < 3 ? 3 : s;
        } else if (k.contains(' $q')) {
          s = s < 2 ? 2 : s;
        } else if (k.contains(q)) {
          s = s < 1 ? 1 : s;
        }
      }
      if (s == 0) continue;
      if (e.inRegion(c)) s += 3;
      scored.add((e, s));
    }
    scored.sort((a, b) {
      final d = b.$2.compareTo(a.$2);
      if (d != 0) return d;
      final t = a.$1.tier.compareTo(b.$1.tier);
      return t != 0 ? t : a.$1.name.length.compareTo(b.$1.name.length);
    });
    return [for (final s in scored.take(limit)) s.$1];
  }

  /// Shown before the user types: the country's brands, best known first,
  /// then international ones.
  List<BrandEntry> popular({int limit = 30}) {
    final c = country;
    List<BrandEntry> byTier(Iterable<BrandEntry> l) {
      final list = l.toList();
      // Inside a tier, the country's own chains before pan-European ones
      // (Esselunga before OBI in Italy). Stable: keeps catalogue order.
      bool home(BrandEntry e) => e.regions.length <= 3;
      return [
        for (final t in [1, 2, 3]) ...[
          ...list.where((e) => e.tier == t && home(e)),
          ...list.where((e) => e.tier == t && !home(e)),
        ],
        ...list.where((e) => e.tier < 1 || e.tier > 3),
      ];
    }

    final local = byTier(_all.where((e) => c != null && e.regions.contains(c)));
    final global = byTier(_all.where((e) => e.regions.contains('global')));
    return {...local, ...global}.take(limit).toList();
  }
}
