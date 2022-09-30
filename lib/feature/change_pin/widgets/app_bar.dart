import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/constants/colors.dart';

class ChangePinAppBar extends StatelessWidget with PreferredSizeWidget {
  const ChangePinAppBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: ColorConstants.primaryColor,
      elevation: 0,
      centerTitle: true,
      title: Text(
        "chanPIN".tr(),
        style: GoogleFonts.montserrat(
            color: Colors.white, fontWeight: FontWeight.w500),
      ),
    );
  }

  @override
  // TODO: implement preferredSize
  Size get preferredSize => Size.fromHeight(8.h);
}
