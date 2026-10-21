import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/utils/search_normalize.dart';

void main() {
  test('Turkish dotted/dotless i and cedilla letters fold to ASCII', () {
    expect(normalizeForSearch('İŞ BANKASI'), 'is bankasi');
    expect(normalizeForSearch('is bankasi'), 'is bankasi');
    expect(normalizeForSearch('Migros'), normalizeForSearch('mıgros'));
    expect(normalizeForSearch('MIGROS'), 'migros');
    expect(normalizeForSearch('Ğ ğ Ü ü Ö ö Ç ç Ş ş'), 'g g u u o o c c s s');
  });

  test('a pre-lowercased İ (i + combining dot) loses the dot', () {
    expect(normalizeForSearch('İ'.toLowerCase()), 'i');
  });

  test('other app languages fold their accents too', () {
    expect(normalizeForSearch('Crédit Agricole'), 'credit agricole');
    expect(normalizeForSearch('Straße'), 'strasse');
    expect(normalizeForSearch('Łódź'), 'lodz');
    expect(normalizeForSearch('Señor'), 'senor');
  });

  test('whitespace collapses and trims', () {
    expect(normalizeForSearch('  Garanti   BBVA \n'), 'garanti bbva');
  });
}
