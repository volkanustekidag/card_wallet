// feature/home/widgets/home_app_bar.dart - GetX Version
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wallet_app/core/controllers/home_controller.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:sizer/sizer.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: ColorConstants.primaryColor,
      actions: [
        IconButton(
            onPressed: () {
              Get.toNamed('/settings')?.then(
                (value) => Get.find<HomeController>().refreshData(),
              );
            },
            icon: Icon(
              Icons.settings,
              size: 20.sp,
              color: Colors.white,
            ))
      ],
      elevation: 0,
      title: Column(
        children: [
          Text(
            "CARD\nWALLET",
            style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 25.sp,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
      toolbarHeight: 100,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100);
}
