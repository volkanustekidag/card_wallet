import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/brands/brand_catalog.dart';

void main() {
  final raw = File('assets/brands/brands.json').readAsStringSync();
  final entries = [
    for (final j in jsonDecode(raw) as List)
      BrandEntry.fromJson(j as Map<String, dynamic>),
  ];
  setUpAll(() => BrandCatalog.instance.debugSetEntries(entries));

  test('catalogue is large, global and well-formed', () {
    expect(entries.length, greaterThan(500));
    final regions = {for (final e in entries) ...e.regions};
    for (final r in ['global', 'us', 'fr', 'de', 'tr', 'cn', 'jp', 'za', 'br', 'pl']) {
      expect(regions, contains(r));
    }
    for (final e in entries) {
      expect(e.domain, isNot(contains('/')), reason: e.name);
      expect(e.domain, contains('.'), reason: e.name);
    }
  });

  test('exact names, aliases and accents match', () {
    final c = BrandCatalog.instance;
    expect(c.match('STARBUCKS')?.domain, 'starbucks.com');
    expect(c.match('Clubcard')?.name, 'Tesco');
    expect(c.match('intermarche')?.name, 'Intermarché');
    expect(c.match('My IKEA Family card')?.domain, 'ikea.com');
    expect(c.match('Luckin')?.domain, 'luckincoffee.com');
    expect(c.match('瑞幸')?.domain, 'luckincoffee.com');
  });

  test('unknown names stay unmatched', () {
    expect(BrandCatalog.instance.match('Corner shop of Ayşe'), isNull);
  });

  test('search ranks prefix matches', () {
    final r = BrandCatalog.instance.search('carre');
    expect(r, isNotEmpty);
    expect(r.first.name.toLowerCase(), startsWith('carre'));
  });
}
