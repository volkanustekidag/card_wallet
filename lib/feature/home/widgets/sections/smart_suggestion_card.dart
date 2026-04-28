import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/controllers/auth_controller.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';

/// One contextual nudge at a time, picked by priority:
///   1. Free tier limit reached → upsell premium.
///   2. ≥ 5 cards saved and biometric not enabled → suggest biometric.
///   3. Otherwise hidden (no nudge if there's nothing meaningful to say).
///
/// The "backup your wallet" suggestion is intentionally deferred — we
/// don't currently track whether the user has ever exported a backup,
/// and showing it permanently would be noise.
class SmartSuggestionCard extends StatelessWidget {
  final HomeController controller;
  const SmartSuggestionCard({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final premium = Get.find<PremiumController>();
    final auth =
        Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;

    return Obx(() {
      final isPremium = premium.isPremium;
      final maxFree = premium.maxCardsForFree;
      final maxLoyalty = premium.maxLoyaltyCardsForFree;
      final ccCount = controller.creditCards.length;
      final ibanCount = controller.ibanCards.length;
      final loyaltyCount = controller.loyaltyCards.length;
      final totalCards = ccCount + ibanCount + loyaltyCount;

      final atLimit = !isPremium &&
          (ccCount >= maxFree ||
              ibanCount >= maxFree ||
              loyaltyCount >= maxLoyalty);

      // Priority 1: free tier limit reached → upsell premium.
      if (atLimit) {
        return _SuggestionTile(
          colorScheme: colorScheme,
          icon: Icons.workspace_premium_rounded,
          title: 'unlockUnlimited'.tr(),
          subtitle: 'unlockUnlimitedSub'.tr(),
          gradient: LinearGradient(
            colors: [
              colorScheme.primaryContainer,
              colorScheme.tertiaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          foreground: colorScheme.onPrimaryContainer,
          onTap: () => Get.toNamed('/premium'),
        );
      }

      // Priority 2: enough cards saved and biometric not yet on.
      final biometricAvailable = auth?.isBiometricAvailable.value ?? false;
      final biometricEnabled = auth?.isBiometricEnabled.value ?? false;
      if (totalCards >= 5 && biometricAvailable && !biometricEnabled) {
        return _SuggestionTile(
          colorScheme: colorScheme,
          icon: Icons.fingerprint_rounded,
          title: 'suggestBiometricTitle'.tr(),
          subtitle: 'suggestBiometricSub'.tr(),
          gradient: LinearGradient(
            colors: [
              colorScheme.secondaryContainer,
              colorScheme.primaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          foreground: colorScheme.onPrimaryContainer,
          onTap: () => Get.toNamed('/settings'),
        );
      }

      return const SizedBox.shrink();
    });
  }
}

class _SuggestionTile extends StatelessWidget {
  final ColorScheme colorScheme;
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final Color foreground;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.colorScheme,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
          child: Container(
            height: kSuggestionHeight,
            padding: const EdgeInsets.symmetric(
              horizontal: kSpaceMd,
              vertical: kSpaceMd,
            ),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: foreground.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: foreground, size: 22),
                ),
                const SizedBox(width: kSpaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: foreground,
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
                          fontWeight: FontWeight.w500,
                          color: foreground.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: foreground.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
