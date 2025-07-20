import 'package:flutter/material.dart';

class Shadows {
  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8.0,
      spreadRadius: -2,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 16.0,
      spreadRadius: -3,
      offset: Offset(0, 16),
    ),
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 48.0,
      offset: Offset(0, 16),
    ),
  ];

  static const List<BoxShadow> shadowStroyLinear = [
    BoxShadow(
      color: Color.fromARGB(9, 0, 0, 0),
      blurRadius: 8.0,
      spreadRadius: -2,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color.fromARGB(19, 0, 0, 0),
      blurRadius: 16.0,
      spreadRadius: -3,
      offset: Offset(0, 16),
    ),
    BoxShadow(
      color: Color.fromARGB(19, 0, 0, 0),
      blurRadius: 48.0,
      offset: Offset(0, 16),
    ),
  ];

  static const List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 6),
      blurRadius: 12,
    ),
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 0.5),
      blurRadius: 4,
    ),
  ];

  static const List<BoxShadow> shadowXSmall = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 4,
      offset: Offset(0, 0.5),
    ),
  ];
}
