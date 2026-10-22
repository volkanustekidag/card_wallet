import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:wallet_app/core/constants/app_locales.dart';

/// Date and number formatters bound to the app's language.
///
/// Never call `DateFormat(...)` / `NumberFormat(...)` without a locale:
/// intl then uses [Intl.systemLocale], which easy_localization sets to the
/// raw device locale. A device in e.g. `chr_GN` makes intl throw
/// "Invalid locale", and a Turkish UI on an English phone shows "Nov 30".
/// Pass the app locale (`context.locale`); anything the app does not ship,
/// or intl has no data for, falls back to English.
abstract final class LocaleFormat {
  /// Resolved intl locale name for date patterns, e.g. `tr_TR` or `tr`.
  static String dateLocale(Locale? locale) =>
      _resolve(locale, DateFormat.localeExists);

  /// Resolved intl locale name for number/currency patterns.
  static String numberLocale(Locale? locale) =>
      _resolve(locale, NumberFormat.localeExists);

  /// "Nov 30" / "30 Kas".
  static DateFormat monthDay(Locale? locale) =>
      DateFormat.MMMd(dateLocale(locale));

  /// "Nov 30, 2026" / "30 Kas 2026".
  static DateFormat yearMonthDay(Locale? locale) =>
      DateFormat.yMMMd(dateLocale(locale));

  static NumberFormat currency(
    Locale? locale, {
    String? symbol,
    int? decimalDigits,
  }) =>
      NumberFormat.currency(
        locale: numberLocale(locale),
        symbol: symbol,
        decimalDigits: decimalDigits,
      );

  static String _resolve(Locale? locale, bool Function(String) exists) {
    final shipped = locale != null &&
        kAppLocales.any((l) => l.languageCode == locale.languageCode);
    if (shipped) {
      final verified = Intl.verifiedLocale(
        locale.toString(),
        exists,
        onFailure: (_) => null,
      );
      if (verified != null) return verified;
    }
    // en_US is intl's built-in default, valid even before any locale data
    // is initialised; once data is loaded this may resolve to plain `en`.
    return Intl.verifiedLocale(
          kFallbackLocale.toString(),
          exists,
          onFailure: (_) => null,
        ) ??
        kFallbackLocale.toString();
  }
}
