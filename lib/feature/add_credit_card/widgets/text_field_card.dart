import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class TextFieldCard extends StatelessWidget {
  final TextEditingController? controller; // Controller eklendi
  final maxLength;
  final inputFormatters;
  final onChanged;
  final textInputType;
  final iconData;
  final hintText;
  final label;

  const TextFieldCard({
    Key? key,
    this.controller, // Controller parametresi
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
    this.textInputType,
    this.iconData,
    this.hintText,
    this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90.w,
      child: TextField(
        controller: controller, // Controller kullan
        maxLength: maxLength,
        keyboardType: textInputType,
        style: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
        onChanged: onChanged,
        inputFormatters: inputFormatters,
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
            helperStyle: GoogleFonts.poppins(
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
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
