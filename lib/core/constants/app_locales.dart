import 'package:flutter/widgets.dart';

/// Languages the app ships translations for (assets/docs/lang). Order is
/// the order shown in the language picker.
const List<Locale> kAppLocales = [
  Locale('en', 'US'),
  Locale('tr', 'TR'),
  Locale('de', 'DE'),
  Locale('fr', 'FR'),
  Locale('es', 'ES'),
  Locale('pt', 'BR'),
  Locale('it', 'IT'),
  Locale('nl', 'NL'),
  Locale('pl', 'PL'),
];

/// Used for any device language outside [kAppLocales].
const Locale kFallbackLocale = Locale('en', 'US');
