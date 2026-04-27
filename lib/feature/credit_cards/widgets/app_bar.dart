import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/feature/credit_cards/controller/credit_card_controller.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/dialogs/card_limit_dialog.dart';
import 'package:wallet_app/core/enums/card_limit_type.dart';

class CCAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CCAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
                onPressed: () async {
                  final premiumController = Get.find<PremiumController>();
                  final currentCount = await premiumController
                      .getStoredCardCount(CardLimitType.credit);

                  if (!premiumController.canAddMoreCreditCards(currentCount)) {
                    final canProceed = await showCardLimitDialog(
                        context, CardLimitType.credit);
                    if (!canProceed) return;
                  }

                  Get.toNamed('/addCreditCard')?.then(
                      (value) =>
                          Get.find<CreditCardController>().loadCreditCards());
                },
                icon: const Icon(
                  Icons.add,
                  size: 28,
                )),
          )
        ],
        title: Text(
          "CC".tr(),
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
