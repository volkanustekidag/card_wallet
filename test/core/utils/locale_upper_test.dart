import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/utils/locale_upper.dart';

void main() {
  test('Turkish dotted/dotless i are upper-cased correctly', () {
    const tr = Locale('tr', 'TR');
    expect(localeUpper('bildirimler', tr), 'BİLDİRİMLER');
    expect(localeUpper('kartı', tr), 'KARTI');
    expect(localeUpper('geçerlilik', tr), 'GEÇERLİLİK');
  });

  test('other languages use the default mapping', () {
    expect(localeUpper('notifications', const Locale('en', 'US')),
        'NOTIFICATIONS');
    expect(localeUpper('gültig bis', const Locale('de', 'DE')), 'GÜLTIG BIS');
    expect(localeUpper('kartı', null), 'KARTI');
  });
}
