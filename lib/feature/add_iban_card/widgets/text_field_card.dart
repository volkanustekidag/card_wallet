import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class TextFieldCard extends StatelessWidget {
  final TextEditingController? controller; // Controller eklendi
  final onChanged;
  final iconData;
  final label;
  final hintText;
  final int maxLength;

  const TextFieldCard({
    Key? key,
    this.controller, // Controller parametresi
    this.onChanged,
    this.iconData,
    this.label,
    this.hintText,
    required this.maxLength,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: controller, // Controller kullan
        maxLength: maxLength,
        onChanged: onChanged,
        decoration: InputDecoration(
            prefixIcon: Icon(
              iconData,
            ),
            labelStyle: GoogleFonts.poppins(
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(width: 1),
            ),
            label: Text(
              label,
            ),
            hintText: hintText),
      ),
    );
  }
}
