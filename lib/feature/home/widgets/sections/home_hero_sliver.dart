import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/widgets/premium_crown_widget.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_formatters.dart';

/// SliverAppBar at the top of home: greeting + 3 stat chips. Collapses on
/// scroll into a slim bar that keeps the settings + premium crown
/// reachable.
class HomeHeroSliver extends StatelessWidget {
  final HomeController controller;
  const HomeHeroSliver({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      pinned: true,
      stretch: true,
      elevation: 0,
      scrolledUnderElevation: 4,
      surfaceTintColor: colorScheme.surfaceTint,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      expandedHeight: kHeroExpandedHeight,
      collapsedHeight: kHeroCollapsedHeight,
      leading: IconButton(
        icon: const Icon(Icons.tune_rounded, size: 22),
        onPressed: () => Get.toNamed('/settings')?.then(
          (_) => controller.refreshData(),
        ),
        tooltip: 'settings'.tr(),
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: kSpaceMd),
          child: Center(child: PremiumCrownWidget(size: 22)),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: _HomeHeroHeader(
          controller: controller,
          isDark: isDark,
          colorScheme: colorScheme,
        ),
      ),
    );
  }
}

class _HomeHeroHeader extends StatelessWidget {
  final HomeController controller;
  final bool isDark;
  final ColorScheme colorScheme;

  const _HomeHeroHeader({
    required this.controller,
    required this.isDark,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = isDark
        ? const [Color(0xFF0F172A), Color(0xFF111827)]
        : const [Color(0xFFFFFFFF), Color(0xFFEEF4FF)];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        kSpaceXL,
        kHeroCollapsedHeight + kSpaceSm,
        kSpaceXL,
        kSpaceLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _WalletGreeting(colorScheme: colorScheme),
          const SizedBox(height: kSpaceLg),
          _StatChipRow(controller: controller),
        ],
      ),
    );
  }
}

class _WalletGreeting extends StatelessWidget {
  final ColorScheme colorScheme;
  const _WalletGreeting({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greetingKey = greetingKeyForHour(hour);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          greetingKey.tr(),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
                fontSize: 24,
                height: 1.1,
              ),
        ),
        const SizedBox(height: kSpaceXS),
        Text(
          'yourWalletSubtitle'.tr(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'Poppins',
                color: colorScheme.onSurface.withValues(alpha: 0.62),
                fontWeight: FontWeight.w400,
              ),
        ),
      ],
    );
  }
}

class _StatChipRow extends StatelessWidget {
  final HomeController controller;
  const _StatChipRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final premium = Get.find<PremiumController>();

    return Obx(() {
      final ccCount = controller.creditCards.length;
      final ibanCount = controller.ibanCards.length;
      final loyaltyCount = controller.loyaltyCards.length;
      final isPremium = premium.isPremium;
      final maxFree = premium.maxCardsForFree;
      final maxLoyalty = premium.maxLoyaltyCardsForFree;

      return Row(
        children: [
          Expanded(
            child: _StatChip(
              icon: Icons.credit_card_rounded,
              count: ccCount,
              label: 'creditShort'.tr(),
              accent: colorScheme.primary,
              warn: !isPremium && ccCount >= maxFree - 1 && ccCount > 0,
              onTap: () => Get.toNamed('/creditCards')?.then(
                (_) => controller.refreshData(),
              ),
            ),
          ),
          const SizedBox(width: kSpaceSm),
          Expanded(
            child: _StatChip(
              icon: Icons.account_balance_rounded,
              count: ibanCount,
              label: 'ibanShort'.tr(),
              accent: colorScheme.secondary,
              warn: !isPremium && ibanCount >= maxFree - 1 && ibanCount > 0,
              onTap: () => Get.toNamed('/ibanCards')?.then(
                (_) => controller.refreshData(),
              ),
            ),
          ),
          const SizedBox(width: kSpaceSm),
          Expanded(
            child: _StatChip(
              icon: Icons.local_offer_rounded,
              count: loyaltyCount,
              label: 'loyaltyShort'.tr(),
              accent: colorScheme.tertiary,
              warn: !isPremium &&
                  loyaltyCount >= maxLoyalty - 1 &&
                  loyaltyCount > 0,
              onTap: () => Get.toNamed('/loyaltyCards')?.then(
                (_) => controller.refreshData(),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color accent;
  final bool warn;
  final VoidCallback onTap;

  const _StatChip({
    required this.icon,
    required this.count,
    required this.label,
    required this.accent,
    required this.warn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kSpaceMd,
            vertical: kSpaceSm + 2,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: accent, size: 18),
                  ),
                  const SizedBox(width: kSpaceSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          compactCount(count),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                    height: 1.1,
                                  ),
                        ),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontFamily: 'Poppins',
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (warn)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.surface,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
