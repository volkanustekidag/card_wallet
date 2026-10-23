import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/brands/brand_region.dart';

void main() {
  test('time zones point to the country the user is in', () {
    expect(countryForTimezone('Europe/Rome'), 'it');
    expect(countryForTimezone('Europe/Paris'), 'fr');
    expect(countryForTimezone('Europe/London'), 'gb');
    expect(countryForTimezone('Europe/Berlin'), 'de');
    expect(countryForTimezone('America/New_York'), 'us');
    expect(countryForTimezone('America/Indiana/Indianapolis'), 'us');
    expect(countryForTimezone('America/Toronto'), 'ca');
    expect(countryForTimezone('Australia/Sydney'), 'au');
    expect(countryForTimezone('Europe/Istanbul'), 'tr');
    expect(countryForTimezone('America/Sao_Paulo'), 'br');
  });

  test('unknown or empty zones give no answer', () {
    expect(countryForTimezone('Etc/UTC'), isNull);
    expect(countryForTimezone(''), isNull);
    expect(countryForTimezone(null), isNull);
  });

  test('country codes are lower case and the UK is gb', () {
    expect(normalizeCountry('IT'), 'it');
    expect(normalizeCountry('UK'), 'gb');
    expect(normalizeCountry('GB'), 'gb');
    expect(normalizeCountry(''), isNull);
  });
}
