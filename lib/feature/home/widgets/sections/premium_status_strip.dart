import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';
import 'package:wallet_app/feature/home/widgets/sections/premium_marks.dart';

/// Evergreen premium upsell shown to free users with at least one card.
/// Drops the older "X/Y limit reached" copy because the per-category
/// math was misleading (a 2/2 strip looked global even when only one
/// kind was full). Limit checks happen at add-time via
/// `goToAddCard` → `showCardLimitDialog`; this strip is just a calm
/// "consider upgrading" nudge.
class PremiumStatusStrip extends StatelessWidget {
  final HomeController controller;
  const PremiumStatusStrip({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final premium = Get.find<PremiumController>();

    return Obx(() {
      if (premium.isPremium) return const _Collapsed();

      // Don't pitch premium to an empty wallet — wait until the user has
      // at least one card so the upsell feels relevant.
      final totalCards = controller.creditCards.length +
          controller.ibanCards.length +
          controller.loyaltyCards.length;
      final shouldShow = totalCards >= 1;

      return AnimatedSize(
        duration: kMediumAnim,
        curve: kHomeCurve,
        alignment: Alignment.topCenter,
        child: AnimatedOpacity(
          duration: kMediumAnim,
          curve: kHomeCurve,
          opacity: shouldShow ? 1 : 0,
          child: shouldShow
              ? _Strip(colorScheme: colorScheme)
              : const _Collapsed(),
        ),
      );
    });
  }
}

class _Collapsed extends StatelessWidget {
  const _Collapsed();
  @override
  Widget build(BuildContext context) => const SizedBox(height: 0);
}

class _Strip extends StatelessWidget {
  final ColorScheme colorScheme;
  const _Strip({required this.colorScheme});

  static const _gold = Color(0xFFC8A14A);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        kSpaceLg,
        kSpaceSm,
        kSpaceLg,
        0,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Get.toNamed('/premium'),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _gold.withValues(alpha: 0.8),
              ),
            ),
            child: Row(
              children: [
                const GoldDiamondMark(size: 14),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'addUnlimitedCards'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: colorScheme.onSurface,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE0B85F), Color(0xFFB8862C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _gold.withValues(alpha: 0.32),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    'getPremium'.tr().toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
