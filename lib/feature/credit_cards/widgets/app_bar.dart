// feature/credit_cards/widgets/app_bar.dart - GetX Version
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:google_fonts/google_fonts.dart';
import 'package:wallet_app/core/controllers/credit_card_controller.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:sizer/sizer.dart';
import 'package:easy_localization/easy_localization.dart';

class CCAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CCAppBar({Key? key}) : super(key: key);

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
      actions: [
        IconButton(
            onPressed: () {
              Get.toNamed('/addCreditCard')?.then((value) =>
                  Get.find<CreditCardController>().loadCreditCards());
            },
            icon: Icon(
              Icons.add,
              color: Colors.white,
              size: 8.w,
            ))
      ],
      leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          )),
      title: Text(
        "CC".tr(),
        style: GoogleFonts.montserrat(
            color: Colors.white, fontWeight: FontWeight.w500),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(8.h);
}
