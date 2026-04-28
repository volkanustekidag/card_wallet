import 'package:flutter/material.dart';

/// Globally common loyalty brands shown as quick-pick chips. The user can
/// always type a custom brand instead — this list just removes friction for
/// the brands most people carry. Curated to be globally relevant; we keep
/// two Turkish chains at the end for the existing TR user base.
class LoyaltyBrandPreset {
  final String name;
  final Color seedColor;
  const LoyaltyBrandPreset(this.name, this.seedColor);
}

const List<LoyaltyBrandPreset> kLoyaltyBrandPresets = [
  // Coffee & food (international chains)
  LoyaltyBrandPreset('Starbucks', Color(0xFF006241)),
  LoyaltyBrandPreset('Costa Coffee', Color(0xFF6F1D1B)),
  LoyaltyBrandPreset('Tim Hortons', Color(0xFFC8102E)),
  LoyaltyBrandPreset('Dunkin\'', Color(0xFFFF671F)),
  LoyaltyBrandPreset('McDonald\'s', Color(0xFFFFC72C)),
  LoyaltyBrandPreset('Burger King', Color(0xFFD62300)),
  LoyaltyBrandPreset('KFC', Color(0xFFF40027)),
  LoyaltyBrandPreset('Subway', Color(0xFF008C15)),
  LoyaltyBrandPreset('Domino\'s', Color(0xFF006491)),

  // Supermarkets (global / regional)
  LoyaltyBrandPreset('Walmart', Color(0xFF0071CE)),
  LoyaltyBrandPreset('Costco', Color(0xFFE31837)),
  LoyaltyBrandPreset('Tesco', Color(0xFF00539F)),
  LoyaltyBrandPreset('Sainsbury\'s', Color(0xFFFF7800)),
  LoyaltyBrandPreset('Carrefour', Color(0xFF003DA5)),
  LoyaltyBrandPreset('Lidl', Color(0xFF0050AA)),
  LoyaltyBrandPreset('Aldi', Color(0xFF00549F)),
  LoyaltyBrandPreset('REWE', Color(0xFFCC071E)),
  LoyaltyBrandPreset('Albert Heijn', Color(0xFF00ADE6)),
  LoyaltyBrandPreset('Mercadona', Color(0xFF008B45)),

  // Pharmacy & beauty
  LoyaltyBrandPreset('Boots', Color(0xFF05054B)),
  LoyaltyBrandPreset('Walgreens', Color(0xFFE31837)),
  LoyaltyBrandPreset('CVS', Color(0xFFCC0000)),
  LoyaltyBrandPreset('Sephora', Color(0xFF000000)),
  LoyaltyBrandPreset('Watsons', Color(0xFF00A99D)),
  LoyaltyBrandPreset('dm', Color(0xFF003D7A)),
  LoyaltyBrandPreset('Rossmann', Color(0xFFE2001A)),

  // Retail & fashion
  LoyaltyBrandPreset('IKEA', Color(0xFF0058A3)),
  LoyaltyBrandPreset('H&M', Color(0xFFE50010)),
  LoyaltyBrandPreset('Zara', Color(0xFF000000)),
  LoyaltyBrandPreset('Uniqlo', Color(0xFFFF0000)),
  LoyaltyBrandPreset('Decathlon', Color(0xFF0082C3)),

  // Electronics
  LoyaltyBrandPreset('Apple', Color(0xFF1D1D1F)),
  LoyaltyBrandPreset('Best Buy', Color(0xFF0046BE)),
  LoyaltyBrandPreset('MediaMarkt', Color(0xFFDC0028)),

  // Fuel
  LoyaltyBrandPreset('Shell', Color(0xFFFFD500)),
  LoyaltyBrandPreset('BP', Color(0xFF009639)),
  LoyaltyBrandPreset('Esso', Color(0xFFCE1126)),
  LoyaltyBrandPreset('Total', Color(0xFFED1C24)),

  // Hotels & airlines (loyalty programs)
  LoyaltyBrandPreset('Marriott Bonvoy', Color(0xFF963E13)),
  LoyaltyBrandPreset('Hilton Honors', Color(0xFF21408E)),
  LoyaltyBrandPreset('IHG One Rewards', Color(0xFF002F87)),
  LoyaltyBrandPreset('Accor', Color(0xFF000000)),
  LoyaltyBrandPreset('Miles & More', Color(0xFF05164D)),
  LoyaltyBrandPreset('Delta SkyMiles', Color(0xFFE31837)),

  // Turkish chains (kept for the existing TR user base — at the end so
  // global users see global brands first)
  LoyaltyBrandPreset('Migros', Color(0xFFE5202D)),
  LoyaltyBrandPreset('BIM', Color(0xFFE52229)),
];
