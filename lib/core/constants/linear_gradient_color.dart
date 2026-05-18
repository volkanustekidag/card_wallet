import 'package:flutter/material.dart';

/// Catalogue of card gradients. Premium-only entries are gated by
/// [GradientCatalogue.isPremium]. Existing user data is kept stable —
/// the first entries match the v1 ordering exactly.
class LinearGradients {
  var linearGradientList = const [
    // --- v1 free gradients (do not reorder) ---
    LinearGradient(colors: [Color(0xffaa076b), Color(0xff61045f)]),
    LinearGradient(colors: [Color(0xFFFF0000), Color(0xFFE81B1E)]),
    LinearGradient(colors: [Color(0xff2b5876), Color(0xff2b5876)]),
    LinearGradient(colors: [Color(0xffff9966), Color(0xffff5e62)]),
    LinearGradient(colors: [Color(0xff141e30), Color(0xff243b55)]),
    LinearGradient(colors: [Color(0xff36d1dc), Color(0xff5b86e5)]),
    LinearGradient(colors: [Color(0xffff512f), Color(0xffdd2476)]),
    LinearGradient(colors: [Color(0xffeacda3), Color(0xffd6ae7b)]),
    LinearGradient(colors: [Color(0xff2c3e50), Color.fromARGB(255, 6, 58, 93)]),
    LinearGradient(colors: [Color(0xff42275a), Color(0xFF3C0634)]),
    LinearGradient(colors: [Color(0xFF006D0B), Color(0xFF02610C)]),
    LinearGradient(colors: [Color(0xFF545454), Color(0xFF2A2A2A)]),
    LinearGradient(
      colors: [
        Color.fromARGB(255, 172, 137, 23),
        Color.fromARGB(255, 227, 209, 91),
      ],
    ),
    // --- M5 premium gradients (index 13+) ---
    LinearGradient(
      colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ), // Midnight
    LinearGradient(
      colors: [Color(0xFFB06AB3), Color(0xFF4568DC)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ), // Aurora
    LinearGradient(
      colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFF6347)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ), // Neon Gold
    LinearGradient(
      colors: [Color(0xFF000000), Color(0xFF1F1F1F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ), // Mat Black
    LinearGradient(
      colors: [Color(0xFFB993D6), Color(0xFF8CA6DB)],
    ), // Lavender
    LinearGradient(
      colors: [Color(0xFFEE9CA7), Color(0xFFFFDDE1)],
    ), // Rose
    LinearGradient(
      colors: [Color(0xFF1FA2FF), Color(0xFF12D8FA), Color(0xFFA6FFCB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ), // Ocean
    LinearGradient(
      colors: [Color(0xFFFC466B), Color(0xFF3F5EFB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ), // Sunset Burst
    LinearGradient(
      colors: [Color(0xFFCB356B), Color(0xFFBD3F32)],
    ), // Crimson
    LinearGradient(
      colors: [
        Color(0xFFA8E063),
        Color(0xFF56AB2F),
      ],
    ), // Spring
  ];
}

/// Static helpers describing the catalogue (free vs premium, total count).
class GradientCatalogue {
  /// First N gradients are available to free users; the rest are gated
  /// behind premium so they show up as a teaser in the picker. Existing
  /// user cards keep their colour regardless of this cap — only the picker
  /// UI gates new selections.
  static const int freeCount = 4;
  static int get totalCount => LinearGradients().linearGradientList.length;

  static bool isPremium(int index) => index >= freeCount;
}
