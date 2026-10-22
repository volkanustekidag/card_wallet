import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

  BrandEntry({
    required this.name,
    required this.domain,
    required this.color,
    required this.regions,
    this.aliases = const [],
    this.kind = '',
  });

  factory BrandEntry.fromJson(Map<String, dynamic> j) => BrandEntry(
        name: j['n'] as String,
        domain: j['d'] as String,
        color: 0xFF000000 | int.parse((j['c'] as String).substring(1), radix: 16),
        regions: (j['r'] as List).cast<String>(),
        aliases: ((j['a'] as List?) ?? const []).cast<String>(),
        kind: (j['k'] as String?) ?? '',
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
      (country != null && regions.contains(country.toLowerCase()));
}

/// Global catalogue of ~700 loyalty brands (all regions, incl. CJK names).
/// Loaded once in the background at startup; until then lookups simply
/// return nothing and the app falls back to what the user typed.
class BrandCatalog {
  BrandCatalog._();
  static final BrandCatalog instance = BrandCatalog._();

  List<BrandEntry> _all = const [];
  Future<void>? _loading;

  bool get isLoaded => _all.isNotEmpty;
  List<BrandEntry> get all => _all;

  /// Device country ("fr", "tr", …) used to rank local brands first.
  String? get country =>
      ui.PlatformDispatcher.instance.locale.countryCode?.toLowerCase();

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
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
      return d != 0 ? d : a.$1.name.length.compareTo(b.$1.name.length);
    });
    return [for (final s in scored.take(limit)) s.$1];
  }

  /// Local brands first (by device country), then global ones.
  List<BrandEntry> popular({int limit = 30}) {
    final c = country;
    final local = _all.where((e) => c != null && e.regions.contains(c));
    final global = _all.where((e) => e.regions.contains('global'));
    return {...local, ...global}.take(limit).toList();
  }
}
