import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/linear_gradient_color.dart';

enum CardFinish { matte, metal }

/// A card face "material": a refined three-stop gradient plus a finish.
///
/// Materials are addressed by the same `colorId` index cards have always
/// stored ([LinearGradients]) so existing cards keep their hue — they just
/// render with depth now. Free/premium gating stays in
/// [GradientCatalogue] and is not changed here.
class CardMaterial {
  final List<Color> colors;
  final CardFinish finish;

  /// Text/icon colour on top of the material.
  final Color foreground;

  const CardMaterial(
    this.colors, {
    this.finish = CardFinish.matte,
    this.foreground = Colors.white,
  });

  bool get isMetal => finish == CardFinish.metal;

  LinearGradient get gradient => LinearGradient(
        begin: const Alignment(-1, -1),
        end: const Alignment(1, 1.2),
        colors: colors,
        stops: colors.length == 3 ? const [0, 0.55, 1] : null,
      );

  /// Dominant colour (widget backgrounds, brand tints, share images).
  Color get base => colors[colors.length > 2 ? 1 : 0];

  // Order mirrors LinearGradients.linearGradientList — never reorder.
  static const List<CardMaterial> catalogue = [
    CardMaterial([Color(0xFF4A1458), Color(0xFF8A2A7E), Color(0xFF2E0B3A)]), // 0 plum
    CardMaterial([Color(0xFF8E1B1F), Color(0xFFD7332F), Color(0xFF6C1013)]), // 1 red
    CardMaterial([Color(0xFF1C3A52), Color(0xFF2F5E7E), Color(0xFF122838)]), // 2 steel
    CardMaterial([Color(0xFFB4452E), Color(0xFFF07856), Color(0xFF8F2F22)]), // 3 coral
    CardMaterial([Color(0xFF0E1626), Color(0xFF263A5A), Color(0xFF0A111D)]), // 4 midnight
    CardMaterial([Color(0xFF136A8A), Color(0xFF3F8FD8), Color(0xFF0E4F6A)]), // 5 sky
    CardMaterial([Color(0xFFA8243E), Color(0xFFEF4A57), Color(0xFF7D1630)]), // 6 rose
    CardMaterial([Color(0xFF8A6A3A), Color(0xFFE2C694), Color(0xFF9E7B45)],
        finish: CardFinish.metal, foreground: Color(0xFF231A0C)), // 7 sand metal
    CardMaterial([Color(0xFF1B2733), Color(0xFF34495E), Color(0xFF121B24)]), // 8 slate
    CardMaterial([Color(0xFF2A0A28), Color(0xFF52164A), Color(0xFF1C0619)]), // 9 aubergine
    CardMaterial([Color(0xFF0D4F3B), Color(0xFF1A8A62), Color(0xFF093A2B)]), // 10 forest
    CardMaterial([Color(0xFF16171C), Color(0xFF3A3C46), Color(0xFF101115)],
        finish: CardFinish.metal), // 11 graphite
    CardMaterial([Color(0xFF8A6512), Color(0xFFE5C866), Color(0xFF9C7418)],
        finish: CardFinish.metal, foreground: Color(0xFF2A1F05)), // 12 gold metal
    CardMaterial([Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)]), // 13 deep sea
    CardMaterial([Color(0xFF7A4BB0), Color(0xFF4F6BD8), Color(0xFF3446A8)]), // 14 aurora
    CardMaterial([Color(0xFFB7791F), Color(0xFFF6B93B), Color(0xFFD9542F)],
        finish: CardFinish.metal), // 15 sunset gold
    CardMaterial([Color(0xFF050506), Color(0xFF1E1F23), Color(0xFF050506)],
        finish: CardFinish.metal), // 16 obsidian
    CardMaterial([Color(0xFF8C79C2), Color(0xFFB7A4E4), Color(0xFF7686C9)]), // 17 lavender
    CardMaterial([Color(0xFFD9848F), Color(0xFFF3C3C9), Color(0xFFCB7480)],
        foreground: Color(0xFF3A1419)), // 18 blush
    CardMaterial([Color(0xFF1479C9), Color(0xFF22B5E0), Color(0xFF3FC4A2)]), // 19 ocean
    CardMaterial([Color(0xFFD9365E), Color(0xFF8F46D6), Color(0xFF3F5EFB)]), // 20 sunset
    CardMaterial([Color(0xFF8E1F3E), Color(0xFFC7344A), Color(0xFF8C2A22)]), // 21 crimson
    CardMaterial([Color(0xFF4F9A2B), Color(0xFF8CC94E), Color(0xFF3B7A20)]), // 22 spring
    CardMaterial([Color(0xFF6B6F76), Color(0xFFD7D9DD), Color(0xFF5D6168)],
        finish: CardFinish.metal, foreground: Color(0xFF111215)), // 23 titanium
  ];

  static int get count => catalogue.length;

  static CardMaterial of(int colorId) {
    if (colorId < 0) return catalogue[2];
    return catalogue[colorId % catalogue.length];
  }

  static bool isPremium(int index) => GradientCatalogue.isPremium(index);

  /// Brand-coloured material (loyalty cards from the brand catalogue).
  factory CardMaterial.brand(Color color) {
    final hsl = HSLColor.fromColor(color);
    final light = hsl.withLightness((hsl.lightness + 0.10).clamp(0.0, 0.92));
    final dark = hsl.withLightness((hsl.lightness - 0.12).clamp(0.04, 1.0));
    final fg = color.computeLuminance() > 0.55
        ? const Color(0xFF111215)
        : Colors.white;
    return CardMaterial(
      [dark.toColor(), color, light.toColor()].reversed.toList(),
      foreground: fg,
    );
  }
}
