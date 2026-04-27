import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/controllers/premium_controller.dart';

class PremiumUpgradeWidget extends StatefulWidget {
  final String? customText;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  const PremiumUpgradeWidget({
    Key? key,
    this.customText,
    this.onTap,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  }) : super(key: key);

  @override
  State<PremiumUpgradeWidget> createState() => _PremiumUpgradeWidgetState();
}

class _PremiumUpgradeWidgetState extends State<PremiumUpgradeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.025).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final premiumController = Get.find<PremiumController>();

      if (premiumController.isPremium) {
        return const SizedBox.shrink();
      }

      return GestureDetector(
        onTap: widget.onTap ?? () => Get.toNamed('/premium'),
        child: ScaleTransition(
          scale: _pulse,
          child: Container(
            margin: widget.margin,
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
                  color: Colors.amber.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.customText ?? "premiumUpgrade".tr(),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
