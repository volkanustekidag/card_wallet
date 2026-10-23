import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// CardWallet v2 design tokens.
///
/// One accent colour; everything else is neutral. Colour in the product
/// comes from the cards, never from the chrome. Use [CwColors.of] to read
/// the palette for the current brightness instead of hard-coding colours.
class CwColors {
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color ink;
  final Color ink2;
  final Color mute;
  final Color line;
  final Color accent;
  final Color accentSoft;
  final Color ok;
  final Color okSoft;
  final Color warn;
  final Color warnSoft;
  final Color danger;
  final Color dangerSoft;

  const CwColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.ink,
    required this.ink2,
    required this.mute,
    required this.line,
    required this.accent,
    required this.accentSoft,
    required this.ok,
    required this.okSoft,
    required this.warn,
    required this.warnSoft,
    required this.danger,
    required this.dangerSoft,
  });

  static const light = CwColors(
    bg: Color(0xFFF6F6F3),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFEDEDE9),
    ink: Color(0xFF0E0F12),
    ink2: Color(0xFF3B3E46),
    mute: Color(0xFF74777F),
    line: Color(0x140E0F12),
    // No brand hue: the cards carry the colour, the chrome stays ink.
    accent: Color(0xFF0E0F12),
    accentSoft: Color(0x0F0E0F12),
    ok: Color(0xFF12B76A),
    okSoft: Color(0xFFDCFCE7),
    warn: Color(0xFFDC6803),
    warnSoft: Color(0xFFFEF0C7),
    danger: Color(0xFFE5484D),
    dangerSoft: Color(0xFFFDE8E8),
  );

  static const dark = CwColors(
    bg: Color(0xFF0B0C0F),
    surface: Color(0xFF16181D),
    surface2: Color(0xFF22252C),
    ink: Color(0xFFF2F3F5),
    ink2: Color(0xFFC9CBD1),
    mute: Color(0xFF8B8F99),
    line: Color(0x14FFFFFF),
    accent: Color(0xFFF2F3F5),
    accentSoft: Color(0x1AF2F3F5),
    ok: Color(0xFF34D399),
    okSoft: Color(0x2634D399),
    warn: Color(0xFFFBBF24),
    warnSoft: Color(0x26FBBF24),
    danger: Color(0xFFF87171),
    dangerSoft: Color(0x26F87171),
  );

  /// Night palette used by onboarding and the paywall regardless of the
  /// user's theme — these are "stage" screens with their own mood.
  static const night = dark;

  static CwColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

class CwRadius {
  CwRadius._();
  static const double s = 8;
  static const double m = 14;
  static const double l = 20;
  static const double xl = 28;
  static const double card = 18;
}

class CwSpace {
  CwSpace._();
  static const double xxs = 4;
  static const double xs = 8;
  static const double s = 12;
  static const double m = 16;
  static const double l = 20;
  static const double xl = 24;
  static const double xxl = 32;

  /// Horizontal page gutter.
  static const double gutter = 18;
}

class CwMotion {
  CwMotion._();
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration base = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);
  static const Curve spring = Curves.easeOutBack;
  static const Curve standard = Curves.easeOutCubic;
}

class CwElevation {
  CwElevation._();

  /// Hairline + tiny shadow for grouped surfaces.
  static List<BoxShadow> e1(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (dark) return const [];
    return const [
      BoxShadow(color: Color(0x0A0E0F12), blurRadius: 2, offset: Offset(0, 1)),
    ];
  }

  /// Lifted objects (cards, FAB, sheets).
  static const List<BoxShadow> e2 = [
    BoxShadow(color: Color(0x290E0F12), blurRadius: 28, offset: Offset(0, 12)),
  ];
}

/// Status/navigation bar icons that read on the page background.
SystemUiOverlayStyle cwOverlayStyle(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
            .copyWith(systemNavigationBarColor: CwColors.dark.bg)
        : SystemUiOverlayStyle.dark
            .copyWith(systemNavigationBarColor: CwColors.light.bg);

/// Wraps a page so the system bars match its background.
class CwPageStyle extends StatelessWidget {
  final Widget child;
  const CwPageStyle({super.key, required this.child});

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: cwOverlayStyle(context),
        child: child,
      );
}
