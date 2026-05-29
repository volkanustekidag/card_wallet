import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/controllers/auth_controller.dart';
import 'package:wallet_app/core/widgets/lifted_surface.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';
import 'package:wallet_app/feature/home/widgets/sections/premium_marks.dart';

/// Currently a single nudge: suggest enabling biometric lock once the
/// user has at least 3 cards (so they're invested) and hardware is
/// available. The premium upsell variant moved to PremiumStatusStrip —
/// keeping it here too created two near-identical cards stacked.
class SmartSuggestionCard extends StatelessWidget {
  final HomeController controller;
  const SmartSuggestionCard({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final auth =
        Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;

    return Obx(() {
      final ccCount = controller.creditCards.length;
      final ibanCount = controller.ibanCards.length;
      final loyaltyCount = controller.loyaltyCards.length;
      final totalCards = ccCount + ibanCount + loyaltyCount;

      final biometricAvailable = auth?.isBiometricAvailable.value ?? false;
      final biometricEnabled = auth?.isBiometricEnabled.value ?? false;
      if (totalCards >= 3 && biometricAvailable && !biometricEnabled) {
        return _SuggestionTile(
          mark: ShieldOutlineMark(size: 18, color: colorScheme.primary),
          eyebrow: 'security'.tr().toUpperCase(),
          eyebrowColor: colorScheme.primary,
          accent: colorScheme.primary,
          title: 'suggestBiometricTitle'.tr(),
          subtitle: 'suggestBiometricSub'.tr(),
          onTap: () => Get.toNamed('/settings'),
        );
      }

      return const SizedBox.shrink();
    });
  }
}

class _SuggestionTile extends StatelessWidget {
  final Widget mark;
  final String eyebrow;
  final Color eyebrowColor;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.mark,
    required this.eyebrow,
    required this.eyebrowColor,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        kSpaceLg,
        kSpaceSm,
        kSpaceLg,
        kSpaceSm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: LiftedSurface(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            border: Border.all(
              color: accent.withValues(alpha: 0.25),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                mark,
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        eyebrow,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                          color: eyebrowColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
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
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
