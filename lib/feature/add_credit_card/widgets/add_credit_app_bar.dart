import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/feature/add_credit_card/controller/add_credit_card_controller.dart';

class AddCreditAppBar extends StatelessWidget implements PreferredSizeWidget {
  final CreditCard? creditCard; // Opsiyonel CreditCard parametresi

  const AddCreditAppBar({Key? key, this.creditCard}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AddCreditCardController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      elevation: 0,
      centerTitle: false,
      titleSpacing: 0,
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
      actions: [
        Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Obx(() {
              final isBusy = controller.isLoading.value;
              final canSave = controller.isFormValid && !isBusy;
              final iconColor = canSave
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.4);
              return IconButton(
                onPressed: canSave ? controller.saveCard : null,
                icon: isBusy
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        controller.isEditMode.value
                            ? Icons.save
                            : Icons.add_card,
                        color: iconColor,
                      ),
              );
            }))
      ],
      title: Obx(() => Text(
            controller.isEditMode.value ? "editCC".tr() : "addCC".tr(),
            style:
                TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
          )),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
