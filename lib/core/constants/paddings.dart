import 'package:flutter/material.dart';

class PaddingConstants extends EdgeInsets {
  const PaddingConstants.normal() : super.all(8.0);
  const PaddingConstants.high() : super.all(10.0);
  const PaddingConstants.extraHigh() : super.all(12.0);
  const PaddingConstants.symmetricHighVertical()
      : super.symmetric(vertical: 16.0);
  const PaddingConstants.symmetricNormalVertical()
      : super.symmetric(horizontal: 8);
}
