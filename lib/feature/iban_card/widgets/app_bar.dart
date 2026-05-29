import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/feature/iban_card/controller/iban_card_controller.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/dialogs/card_limit_dialog.dart';
import 'package:wallet_app/core/enums/card_limit_type.dart';

class IbanCardsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const IbanCardsAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      title: Text(
        "IC".tr(),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      titleSpacing: 0,
      centerTitle: false,
      backgroundColor: colorScheme.surface,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.add_rounded),
          tooltip: 'addIbanCard'.tr(),
          onPressed: () async {
            final premiumController = Get.find<PremiumController>();
            final currentCount = await premiumController
                .getStoredCardCount(CardLimitType.iban);

            if (!premiumController.canAddMoreIbanCards(currentCount)) {
              final canProceed =
                  await showCardLimitDialog(context, CardLimitType.iban);
              if (!canProceed) return;
            }

            Get.toNamed('/addIbanCard')?.then(
                (value) => Get.find<IbanCardController>().loadIbanCards());
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
