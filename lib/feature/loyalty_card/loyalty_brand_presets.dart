import 'package:flutter/material.dart';

/// Hand-curated list of common loyalty brands. The colour is paired with
/// [LinearGradients] entries; if a brand has no preset the user picks a
/// gradient and types the name manually.
class LoyaltyBrandPreset {
  final String name;
  final Color seedColor;
  const LoyaltyBrandPreset(this.name, this.seedColor);
}

const List<LoyaltyBrandPreset> kLoyaltyBrandPresets = [
  // Turkish supermarkets / retailers
  LoyaltyBrandPreset('Migros', Color(0xFFE5202D)),
  LoyaltyBrandPreset('CarrefourSA', Color(0xFF0E5BAB)),
  LoyaltyBrandPreset('BIM', Color(0xFFE52229)),
  LoyaltyBrandPreset('A101', Color(0xFFD8232A)),
  LoyaltyBrandPreset('Şok', Color(0xFFFFC700)),
  LoyaltyBrandPreset('Macrocenter', Color(0xFF005EB8)),
  LoyaltyBrandPreset('Hepsiburada', Color(0xFFFF6000)),
  LoyaltyBrandPreset('Trendyol', Color(0xFFF27A1A)),
  LoyaltyBrandPreset('Boyner', Color(0xFF000000)),
  LoyaltyBrandPreset('Watsons', Color(0xFF00A99D)),
  LoyaltyBrandPreset('Decathlon', Color(0xFF0082C3)),
  LoyaltyBrandPreset('IKEA', Color(0xFF0058A3)),
  LoyaltyBrandPreset('MediaMarkt', Color(0xFFDC0028)),
  LoyaltyBrandPreset('Teknosa', Color(0xFFE53935)),
  // Coffee / food
  LoyaltyBrandPreset('Starbucks', Color(0xFF006241)),
  LoyaltyBrandPreset('Espressolab', Color(0xFF8B5E34)),
  LoyaltyBrandPreset('Tchibo', Color(0xFF003366)),
  LoyaltyBrandPreset('Burger King', Color(0xFFD62300)),
  LoyaltyBrandPreset('McDonalds', Color(0xFFFFC72C)),
  LoyaltyBrandPreset('Domino\'s', Color(0xFF006491)),
  LoyaltyBrandPreset('TAB Gıda', Color(0xFFE40521)),
  // Fuel / pharmacy
  LoyaltyBrandPreset('Shell', Color(0xFFFFD500)),
  LoyaltyBrandPreset('OPET', Color(0xFFE60012)),
  LoyaltyBrandPreset('BP', Color(0xFF009639)),
  LoyaltyBrandPreset('Petrol Ofisi', Color(0xFF005DAC)),
  LoyaltyBrandPreset('Eczane', Color(0xFF34A853)),
];
