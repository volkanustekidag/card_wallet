import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _langs = [
  'en-US', 'tr-TR', 'de-DE', 'fr-FR', 'es-ES', 'pt-BR', 'it-IT', 'nl-NL', 'pl-PL',
];

Map<String, dynamic> _load(String lang) =>
    jsonDecode(File('assets/docs/lang/$lang.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('all 9 language files have the same keys', () {
    final reference = _load('en-US').keys.toSet();
    for (final lang in _langs.skip(1)) {
      final keys = _load(lang).keys.toSet();
      expect(reference.difference(keys), isEmpty, reason: '$lang is missing');
      expect(keys.difference(reference), isEmpty, reason: '$lang has extra');
    }
  });

  test('positional placeholders match across languages', () {
    final en = _load('en-US');
    for (final lang in _langs.skip(1)) {
      final other = _load(lang);
      for (final key in en.keys) {
        final a = '{}'.allMatches('${en[key]}').length;
        final b = '{}'.allMatches('${other[key]}').length;
        expect(b, a, reason: '$lang:$key placeholder count');
      }
    }
  });

  test('paywall legal text names the right store per platform', () {
    for (final lang in _langs) {
      final t = _load(lang);
      final android = t['premiumLegalDisclosureAndroid'] as String;
      final ios = t['premiumLegalDisclosureIos'] as String;
      expect(android, contains('Google Play'), reason: lang);
      expect(android, isNot(contains('Apple')), reason: lang);
      expect(android, isNot(contains('App Store')), reason: lang);
      expect(ios, contains('Apple'), reason: lang);
      expect(ios, isNot(contains('Google')), reason: lang);
    }
  });
}
