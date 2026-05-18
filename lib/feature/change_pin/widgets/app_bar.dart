import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ChangePinAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChangePinAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: Text(
        "chanPIN".tr(),
        style: const TextStyle(
            fontFamily: 'Poppins', fontWeight: FontWeight.w500),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
