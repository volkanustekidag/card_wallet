import 'package:flutter/widgets.dart';

/// Locale-aware upper-casing for UI labels.
///
/// Dart's [String.toUpperCase] is locale-independent, so Turkish "i" becomes
/// "I" ("BILDIRIMLER") instead of "İ" ("BİLDİRİMLER"), and "ı" is left alone
/// on some platforms. Use this for translated captions only — never for
/// barcodes, IBANs, hex values or card holder names typed by the user.
String localeUpper(String text, Locale? locale) {
  final lang = locale?.languageCode;
  if (lang == 'tr' || lang == 'az') {
    text = text.replaceAll('i', 'İ').replaceAll('ı', 'I');
  }
  return text.toUpperCase();
}

extension LocaleUpperContext on BuildContext {
  /// [localeUpper] with the app's current locale.
  String upper(String text) =>
      localeUpper(text, Localizations.maybeLocaleOf(this));
}
