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
        final a = _placeholders(en[key]);
        final b = _placeholders(other[key]);
        expect(b, a, reason: '$lang:$key placeholder count');
      }
    }
  });

  test('paywall renewal terms carry the price in every language', () {
    // Shown under the buy button for the selected plan: the price, that it
    // renews automatically, and that it can be cancelled (store rules).
    for (final lang in _langs) {
      final t = _load(lang);
      for (final key in ['cwRenewsYear', 'cwRenewsMonth', 'cwRenewsWeek']) {
        final text = t[key] as String?;
        expect(text, isNotNull, reason: '$lang:$key');
        expect('{}'.allMatches(text!).length, 1, reason: '$lang:$key');
      }
      expect(t['cwTerms'], isNotNull, reason: lang);
      expect(t['cwPrivacy'], isNotNull, reason: lang);
    }
  });
}

/// `{}` count of a string, or of the `other` form of a plural map (forms
/// differ per language: Polish has few/many, English has one/other).
int _placeholders(dynamic value) => value is Map
    ? _placeholders(value['other'])
    : '{}'.allMatches('$value').length;
