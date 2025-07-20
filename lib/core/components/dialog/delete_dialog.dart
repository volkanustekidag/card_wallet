import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/constants/paddings.dart';

class CustomDialog extends StatelessWidget {
  const CustomDialog({
    Key? key,
    this.onConfirm,
    this.title = "areUSure",
    this.cancelText = "cancel",
  }) : super(key: key);

  final Function? onConfirm;
  final String title;
  final String cancelText;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 40.h,
        width: 80.w,
        decoration: BoxDecoration(
            color: context.theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.info,
              size: 18.w,
            ),
            Padding(
              padding: PaddingConstants.normal(),
              child: DefaultTextStyle(
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: context.theme.colorScheme.onSurface,
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Padding(
              padding: PaddingConstants.normal(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(),
                    child: Text(cancelText),
                  ),
                  ElevatedButton(
                    onPressed: () async {},
                    style: ElevatedButton.styleFrom(),
                    child: Text("delete".tr()),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
