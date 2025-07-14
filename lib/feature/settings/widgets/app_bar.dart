import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sizer/sizer.dart';

class SettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SettingsAppBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                ColorConstants.primaryColor.withOpacity(0.5),
                ColorConstants.primaryColor.withOpacity(0.1),
              ]),
        ),
      ),
      leading: IconButton(
          onPressed: () => Navigator.pop(
                context,
              ),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          )),
      title: Text(
        "settings".tr(),
        style: GoogleFonts.montserrat(
            color: Colors.white, fontWeight: FontWeight.w500),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  @override
  // TODO: implement preferredSize
  Size get preferredSize => Size.fromHeight(8.h);
}
