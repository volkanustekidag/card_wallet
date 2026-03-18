import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wallet_app/core/constants/app_images.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';

class PremiumCrownWidget extends StatelessWidget {
  final double size;
  final Color? color;

  const PremiumCrownWidget({
    Key? key,
    this.size = 24.0,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final premiumController = Get.find<PremiumController>();

      if (!premiumController.isPremium) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Image.asset(
          AppImages.king,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    });
  }
}
