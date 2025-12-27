import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:easy_localization/easy_localization.dart';

class ChangePinAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChangePinAppBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      title: Text(
        "chanPIN".tr(),
        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
      ),
    );
  }

  @override
  // TODO: implement preferredSize
  Size get preferredSize => Size.fromHeight(6.h);
}
