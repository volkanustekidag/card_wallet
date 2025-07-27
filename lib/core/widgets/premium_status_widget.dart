import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';

class PremiumStatusWidget extends StatelessWidget {
  const PremiumStatusWidget(
      {Key? key,
      this.margin = const EdgeInsets.symmetric(horizontal: 32, vertical: 8)})
      : super(key: key);

  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final premiumController = Get.find<PremiumController>();

      if (!premiumController.isPremium) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: margin,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.amber, Colors.orange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.workspace_premium,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Premium Active',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      );
    });
  }
}
