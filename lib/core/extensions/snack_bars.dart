import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

extension SnackBars on BuildContext {
  showSnackBarInfo(context, color, content) {
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        duration: const Duration(seconds: 1),
        content: Text(
          "${content}".tr(),
          style: GoogleFonts.montserrat(
              color: Colors.white, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }
}
