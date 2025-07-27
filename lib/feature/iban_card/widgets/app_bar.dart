// feature/iban_card/widgets/app_bar.dart - GetX Version
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:google_fonts/google_fonts.dart';
import 'package:wallet_app/feature/iban_card/controller/iban_card_controller.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/data/services/admob_service.dart';
import 'package:sizer/sizer.dart';
import 'package:easy_localization/easy_localization.dart';

class IbanCardsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const IbanCardsAppBar({Key? key}) : super(key: key);

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
                  // Premium kullanıcılara interstitial reklam gösterme
                  if (!premiumController.isPremium) {
                    await AdMobService.showInterstitialAd();
                  }
                  Get.toNamed('/addIbanCard')?.then((value) =>
                      Get.find<IbanCardController>().loadIbanCards());
                },
                icon: Icon(
                  Icons.add,
                  size: 8.w,
                )),
          )
        ],
        leading: IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(
              Icons.arrow_back,
            )),
        title: Text(
          "IC".tr(),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(8.h);
}
