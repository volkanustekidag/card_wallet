import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/widgets/premium_crown_widget.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_formatters.dart';

/// SliverAppBar at the top of home: a calm time-of-day greeting and the
/// premium crown / settings entry. Kept deliberately spare — the previous
/// 3-stat-chip row was busy and added scroll height for information the
/// shelves themselves already convey through count badges.
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
        background: _HomeHeroHeader(isDark: isDark, colorScheme: colorScheme),
      ),
    );
  }
}

class _HomeHeroHeader extends StatelessWidget {
  final bool isDark;
  final ColorScheme colorScheme;
  const _HomeHeroHeader({required this.isDark, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final gradientColors = isDark
        ? const [Color(0xFF0F172A), Color(0xFF111827)]
        : const [Color(0xFFFFFFFF), Color(0xFFEEF4FF)];
    final hour = DateTime.now().hour;
    final greetingKey = greetingKeyForHour(hour);

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
        kHeroCollapsedHeight + kSpaceXS,
        kSpaceXL,
        kSpaceMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            greetingKey.tr(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  height: 1.1,
                ),
          ),
          const SizedBox(height: kSpaceXS),
          Text(
            'yourWalletSubtitle'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'Poppins',
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w400,
                ),
          ),
        ],
      ),
    );
  }
}
