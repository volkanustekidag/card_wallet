import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/widgets/banner_ad_widget.dart';

class PremiumBannerAdWidget extends StatelessWidget {
  const PremiumBannerAdWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final premiumController = Get.find<PremiumController>();
      
      // Premium kullanıcılara reklam gösterme
      if (premiumController.isPremium) {
        return const SizedBox.shrink();
      }
      
      // Premium olmayanlara reklam göster
      return const BannerAdWidget();
    });
  }
}