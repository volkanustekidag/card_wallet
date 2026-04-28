import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/enums/card_limit_type.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/feature/home/widgets/sections/add_card_navigator.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';

/// Four-up shortcut row: add credit / add iban / add loyalty / search.
/// Replaces the cramped 3-button bar that used 12 sp text and squeezed
/// icon + text into 72 dp. Now each tile gets a clear circular icon plate
/// with a bottom label and a clean tap target.
class QuickActionRail extends StatelessWidget {
  final HomeController controller;
  const QuickActionRail({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        kSpaceLg,
        kSpaceLg,
        kSpaceLg,
        kSpaceSm,
      ),
      child: SizedBox(
        height: kQuickActionRailHeight,
        child: Row(
          children: [
            Expanded(
              child: _QuickActionTile(
                icon: Icons.credit_card_rounded,
                label: 'addCC'.tr(),
                accent: colorScheme.primary,
                onTap: () => goToAddCard(
                  context: context,
                  type: CardLimitType.credit,
                ),
              ),
            ),
            const SizedBox(width: kSpaceSm),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.account_balance_rounded,
                label: 'addIC'.tr(),
                accent: colorScheme.secondary,
                onTap: () => goToAddCard(
                  context: context,
                  type: CardLimitType.iban,
                ),
              ),
            ),
            const SizedBox(width: kSpaceSm),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.local_offer_rounded,
                label: 'addLC'.tr(),
                accent: colorScheme.tertiary,
                onTap: () => goToAddCard(
                  context: context,
                  type: CardLimitType.loyalty,
                ),
              ),
            ),
            const SizedBox(width: kSpaceSm),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.search_rounded,
                label: 'search'.tr(),
                accent: colorScheme.onSurface.withValues(alpha: 0.78),
                onTap: () {
                  HapticFeedback.lightImpact();
                  // First milestone: jump into the credit cards list which
                  // already has CardSearchBar at the top. A standalone
                  // global search page is a v2 task.
                  Get.toNamed('/creditCards')?.then(
                    (_) => controller.refreshData(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile> {
  double _scale = 1;

  void _press(bool down) {
    setState(() => _scale = down ? 0.94 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTapDown: (_) => _press(true),
      onTapCancel: () => _press(false),
      onTapUp: (_) => _press(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: kFastAnim,
        curve: Curves.easeOut,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: kQuickActionTileSize,
              height: kQuickActionTileSize,
              decoration: BoxDecoration(
                color: widget.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(widget.icon, color: widget.accent, size: 26),
            ),
            const SizedBox(height: kSpaceSm),
            Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.78),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
