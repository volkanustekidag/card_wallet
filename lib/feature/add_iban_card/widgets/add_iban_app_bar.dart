import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/feature/add_iban_card/controller/add_iban_card_controller.dart';

class AddIbanAppBar extends StatelessWidget implements PreferredSizeWidget {
  final IbanCard? ibanCard; // Opsiyonel IbanCard parametresi

  const AddIbanAppBar({Key? key, this.ibanCard}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AddIbanCardController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      child: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            controller.resetCard();
            Get.back();
          },
          icon: const Icon(
            Icons.arrow_back,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Obx(() => IconButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () {
                          controller.saveCard();
                        },
                  icon: controller.isLoading.value
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          controller.isEditMode.value
                              ? Icons.save
                              : Icons.add_card,
                        ),
                )),
          )
        ],
        title: Obx(() => Text(
              controller.isEditMode.value ? "editIC".tr() : "addIC".tr(),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w400),
            )),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(8.h);
}
