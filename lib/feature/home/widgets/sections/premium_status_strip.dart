import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';

/// Slim banner shown only when a free user is approaching or at the free
/// card limit. Replaces the old PremiumUpgradeWidget pulse banner — that
/// always-visible amber bar plus its 2.2 s pulse loop was tedious. This
/// one stays out of the way until it's actually relevant.
class PremiumStatusStrip extends StatelessWidget {
  final HomeController controller;
  const PremiumStatusStrip({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final premium = Get.find<PremiumController>();

    return Obx(() {
      final isPremium = premium.isPremium;
      if (isPremium) {
        return const _Collapsed();
      }

      final maxFree = premium.maxCardsForFree;
      final maxLoyalty = premium.maxLoyaltyCardsForFree;
      final ccCount = controller.creditCards.length;
      final ibanCount = controller.ibanCards.length;
      final loyaltyCount = controller.loyaltyCards.length;

      // Most-pressing limit drives the wording (whichever has the smallest
      // remaining slots). Hidden entirely if every kind has slack.
      final remaining = <String, int>{
        'creditShort': maxFree - ccCount,
        'ibanShort': maxFree - ibanCount,
        'loyaltyShort': maxLoyalty - loyaltyCount,
      };
      final sorted = remaining.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      final tightest = sorted.first;

      // Show only when the tightest category has ≤ 1 free slot remaining
      // and the user has at least one card there (so we don't nag empty
      // wallets).
      final tightCount = _countFor(tightest.key, ccCount, ibanCount, loyaltyCount);
      final tightMax = tightest.key == 'loyaltyShort' ? maxLoyalty : maxFree;
      final shouldShow = tightest.value <= 1 && tightCount > 0;

      return AnimatedSize(
        duration: kMediumAnim,
        curve: kHomeCurve,
        alignment: Alignment.topCenter,
        child: AnimatedOpacity(
          duration: kMediumAnim,
          curve: kHomeCurve,
          opacity: shouldShow ? 1 : 0,
          child: shouldShow
              ? _Strip(
                  colorScheme: colorScheme,
                  category: tightest.key.tr(),
                  used: tightCount,
                  max: tightMax,
                )
              : const _Collapsed(),
        ),
      );
    });
  }

  int _countFor(String key, int cc, int iban, int loyalty) {
    switch (key) {
      case 'creditShort':
        return cc;
      case 'ibanShort':
        return iban;
      case 'loyaltyShort':
        return loyalty;
      default:
        return 0;
    }
  }
}

class _Collapsed extends StatelessWidget {
  const _Collapsed();
  @override
  Widget build(BuildContext context) => const SizedBox(height: 0);
}

class _Strip extends StatelessWidget {
  final ColorScheme colorScheme;
  final String category;
  final int used;
  final int max;

  const _Strip({
    required this.colorScheme,
    required this.category,
    required this.used,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    final atLimit = used >= max;
    final title =
        atLimit ? 'freeLimitReached'.tr() : 'freeLimitNearTitle'.tr();
    final subtitle = 'freeLimitNearSubtitle'.tr(args: ['$used', '$max']);

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
              horizontal: kSpaceMd,
              vertical: kSpaceSm + 2,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB800), Color(0xFFFF7A00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF7A00).withValues(alpha: 0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: kSpaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        '$subtitle · $category',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
