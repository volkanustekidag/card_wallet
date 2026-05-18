import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/feature/home/widgets/sections/premium_marks.dart';

/// Premium "active" badge for the settings screen. Mirrors the visual
/// language of `PremiumUpgradeWidget` — surface container background,
/// thin gold accent border, gold diamond mark, gold-gradient pill — so
/// the upsell and the active state read as one design system. The
/// right-side pill carries a check tick instead of a CTA to signal that
/// premium is already on.
class PremiumStatusWidget extends StatelessWidget {
  const PremiumStatusWidget({
    Key? key,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  }) : super(key: key);

  final EdgeInsetsGeometry? margin;

  static const _gold = Color(0xFFC8A14A);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final premiumController = Get.find<PremiumController>();
      if (!premiumController.isPremium) {
        return const SizedBox.shrink();
      }

      final colorScheme = Theme.of(context).colorScheme;
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _gold.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const GoldDiamondMark(size: 18),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'premium'.tr().toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                        color: _gold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'premiumActive'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE0B85F), Color(0xFFB8862C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _gold.withValues(alpha: 0.32),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
