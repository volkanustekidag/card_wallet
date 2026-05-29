import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/feature/add_iban_card/controller/add_iban_card_controller.dart';

class AddIbanAppBar extends StatelessWidget implements PreferredSizeWidget {
  final IbanCard? ibanCard;

  const AddIbanAppBar({Key? key, this.ibanCard}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AddIbanCardController>();

    return AppBar(
      elevation: 0,
      titleSpacing: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () {
          controller.resetCard();
          Get.back();
        },
        icon: Icon(
          Platform.isIOS ? Icons.arrow_back_ios : Icons.arrow_back,
        ),
      ),
      title: Obx(() => Text(
            controller.isEditMode.value ? "editIC".tr() : "addIC".tr(),
            style:
                TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400),
          )),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
