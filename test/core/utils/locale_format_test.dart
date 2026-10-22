import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/date_symbol_data_local.dart';
import 'package:wallet_app/core/utils/locale_format.dart';

void main() {
  final nov30 = DateTime(2026, 11, 30);
  const chrGN = Locale('chr', 'GN');
  const trTR = Locale('tr', 'TR');

  setUpAll(() async {
    // In the app GlobalMaterialLocalizations loads the date symbols.
    await initializeDateFormatting();
  });

  tearDown(() {
    Intl.systemLocale = 'en_US';
    Intl.defaultLocale = null;
  });

  test('a locale-less formatter crashes on a device locale without data', () {
    // What easy_localization's findSystemLocale() leaves behind. In the app
    // only Flutter's date symbols are loaded and they have no `chr`; the
    // full intl data used here does, so use a code intl has never heard of.
    Intl.systemLocale = 'qq_GN';
    expect(() => DateFormat.MMMd().format(nov30), throwsArgumentError);
    expect(LocaleFormat.monthDay(const Locale('qq', 'GN')).format(nov30),
        'Nov 30');
  });

  group('chr_GN', () {
    test('falls back to English instead of throwing', () {
      Intl.systemLocale = 'chr_GN';

      expect(LocaleFormat.dateLocale(chrGN), startsWith('en'));
      expect(LocaleFormat.numberLocale(chrGN), startsWith('en'));
      expect(LocaleFormat.monthDay(chrGN).format(nov30), 'Nov 30');
      expect(LocaleFormat.yearMonthDay(chrGN).format(nov30), 'Nov 30, 2026');
      expect(
        LocaleFormat.currency(chrGN, symbol: r'$', decimalDigits: 2)
            .format(1234.5),
        r'$1,234.50',
      );
    });

    test('null locale also falls back to English', () {
      Intl.systemLocale = 'chr_GN';
      expect(LocaleFormat.monthDay(null).format(nov30), 'Nov 30');
    });
  });

  group('tr_TR', () {
    test('formats in Turkish even when the device is English', () {
      Intl.systemLocale = 'en_US';

      expect(LocaleFormat.dateLocale(trTR), startsWith('tr'));
      expect(LocaleFormat.monthDay(trTR).format(nov30), '30 Kas');
      expect(LocaleFormat.yearMonthDay(trTR).format(nov30), '30 Kas 2026');
      expect(
        LocaleFormat.currency(trTR, symbol: '₺', decimalDigits: 2)
            .format(1234.5),
        '₺1.234,50',
      );
    });
  });

  test('a locale the app does not ship falls back to English', () {
    // intl has Japanese data, but the UI around the date would be English.
    expect(
      LocaleFormat.monthDay(const Locale('ja', 'JP')).format(nov30),
      'Nov 30',
    );
  });
}
