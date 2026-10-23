import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/brands/brand_catalog.dart';
import 'package:wallet_app/core/services/ui_prefs.dart';

void main() {
  final raw = File('assets/brands/brands.json').readAsStringSync();
  final entries = [
    for (final j in jsonDecode(raw) as List)
      BrandEntry.fromJson(j as Map<String, dynamic>),
  ];
  setUpAll(() => BrandCatalog.instance.debugSetEntries(entries));
  tearDown(() {
    UiPrefs.instance.brandCountry.value = null;
    BrandCatalog.instance.debugZoneCountry = null;
  });

  /// Pretends the user is in [country].
  void inCountry(String country) =>
      UiPrefs.instance.brandCountry.value = country;

  test('catalogue is large, global and well-formed', () {
    expect(entries.length, greaterThan(500));
    final regions = {for (final e in entries) ...e.regions};
    for (final r in [
      'global',
      'us',
      'fr',
      'de',
      'tr',
      'cn',
      'jp',
      'za',
      'br',
      'pl'
    ]) {
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

  test('every target market has a real local list', () {
    const markets = [
      'us', 'ca', 'gb', 'ie', 'au', 'de', 'at', 'ch', 'fr', 'be', 'nl', //
      'it', 'es', 'pt', 'pl', 'tr', 'br',
    ];
    for (final m in markets) {
      final local = entries.where((e) => e.regions.contains(m)).length;
      expect(local, greaterThanOrEqualTo(15), reason: m);
    }
    expect(entries.any((e) => e.regions.contains('uk')), isFalse);
  });

  test('no brand is listed twice for the same country', () {
    final seen = <String>{};
    for (final e in entries) {
      for (final r in e.regions) {
        expect(seen.add('${e.name.toLowerCase()}|$r'), isTrue,
            reason: '${e.name} in $r');
      }
    }
  });

  test('before typing, the country\'s best-known brands come first', () {
    inCountry('it');
    final top = BrandCatalog.instance.popular(limit: 8).map((e) => e.name);
    expect(top, containsAll(['Esselunga', 'Conad', 'Coop']));
    expect(top, isNot(contains('Walmart')));

    inCountry('us');
    final us = BrandCatalog.instance.popular(limit: 8).map((e) => e.name);
    expect(us, containsAll(['Target', 'Kroger', 'CVS']));
    expect(us, isNot(contains('Esselunga')));
  });

  test('same name, different country: the local one wins', () {
    inCountry('ch');
    expect(BrandCatalog.instance.search('migros').first.domain, 'migros.ch');
    expect(BrandCatalog.instance.match('Coop')?.domain, 'coop.ch');
    inCountry('tr');
    expect(
        BrandCatalog.instance.search('migros').first.domain, 'migros.com.tr');
    inCountry('it');
    expect(BrandCatalog.instance.match('Coop')?.domain, 'e-coop.it');
  });

  test('regional chains rank above foreign ones while typing', () {
    inCountry('fr');
    expect(BrandCatalog.instance.search('carr').first.name, 'Carrefour');
    inCountry('gb');
    expect(BrandCatalog.instance.search('tes').first.name, 'Tesco');
  });

  test('the user\'s pick beats the time zone, which beats the locale', () {
    final c = BrandCatalog.instance;
    c.debugZoneCountry = 'it';
    expect(c.country, 'it');
    inCountry('fr');
    expect(c.country, 'fr');
    expect(c.detectedCountry, 'it');
    UiPrefs.instance.brandCountry.value = 'uk';
    expect(c.country, 'gb');
  });
}
