import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

class CustomDialog extends StatelessWidget {
  const CustomDialog({
    Key? key,
    this.onConfirm,
    this.title = "areUSure",
    this.cancelText = "cancel",
    this.content,
    this.confirmText = "yes",
  }) : super(key: key);

  final Function? onConfirm;
  final String title;
  final String cancelText;
  final String? content;
  final String confirmText;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title.tr(),
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      content: content != null
          ? Text(
              content!.tr(),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            )
          : null,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            cancelText.tr(),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (onConfirm != null) {
              onConfirm!();
            }
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            confirmText.tr(),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
