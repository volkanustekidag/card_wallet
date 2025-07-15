import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/controllers/add_iban_card_controller.dart';

class AddIbanAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AddIbanAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AddIbanCardController>();

    return AppBar(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        onPressed: () {
          controller.resetCard();
          Get.back();
        },
        icon: const Icon(
          Icons.arrow_back_ios,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            controller.saveCard();
          },
          icon: const Icon(
            Icons.add_card,
            color: Colors.white,
          ),
        )
      ],
      title: Text(
        "addIC".tr(),
        style: GoogleFonts.montserrat(
            color: Colors.white, fontWeight: FontWeight.w400),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(8.h);
}
