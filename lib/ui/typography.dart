import 'package:flutter/material.dart';

/// Type scale. The UI uses the platform font (SF Pro on iOS, Roboto on
/// Android) — the app should feel native, not like a template. The big
/// titles ([display]) are the brand's face: Instrument Sans. Numbers that
/// users read or copy (card numbers, IBANs, barcodes) use [CwType.mono].
class CwType {
  CwType._();

  static const String monoFamily = 'JetBrainsMono';
  static const String brandFamily = 'InstrumentSans';

  static const TextStyle display = TextStyle(
    fontFamily: brandFamily,
    fontSize: 34,
    height: 1.08,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.7,
  );

  static const TextStyle title = TextStyle(
    fontSize: 22,
    height: 1.18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 17,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle callout = TextStyle(
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle footnote = TextStyle(
    fontSize: 13,
    height: 1.35,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  /// Small uppercase label (section headers, card type tags).
  static const TextStyle overline = TextStyle(
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );

  static TextStyle mono({
    double size = 16,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double letterSpacing = 1.2,
  }) =>
      TextStyle(
        fontFamily: monoFamily,
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        fontFeatures: const [FontFeature.tabularFigures()],
        height: 1.2,
      );

  static TextTheme textTheme(Color ink, Color mute) => TextTheme(
        displaySmall: display.copyWith(color: ink),
        headlineMedium: display.copyWith(color: ink),
        headlineSmall: title.copyWith(color: ink),
        titleLarge: title.copyWith(color: ink),
        titleMedium: headline.copyWith(color: ink),
        titleSmall: callout.copyWith(color: ink, fontWeight: FontWeight.w600),
        bodyLarge: body.copyWith(color: ink),
        bodyMedium: body.copyWith(color: ink),
        bodySmall: footnote.copyWith(color: mute),
        labelLarge: callout.copyWith(color: ink, fontWeight: FontWeight.w600),
        labelMedium: caption.copyWith(color: mute),
        labelSmall: overline.copyWith(color: mute),
      );
}
