import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/dialogs/card_limit_dialog.dart';
import 'package:wallet_app/core/enums/card_limit_type.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';

/// Centralised "navigate to add-card" with the premium-limit gate.
/// Both QuickActionRail and AddCardTile call this so the limit logic only
/// lives in one place. Pre-existing logic was duplicated across body.dart
/// and DashedEmptyCard.
Future<void> goToAddCard({
  required BuildContext context,
  required CardLimitType type,
}) async {
  HapticFeedback.lightImpact();
  final premium = Get.find<PremiumController>();
  final count = await premium.getStoredCardCount(type);

  bool canAdd;
  switch (type) {
    case CardLimitType.credit:
      canAdd = premium.canAddMoreCreditCards(count);
      break;
    case CardLimitType.iban:
      canAdd = premium.canAddMoreIbanCards(count);
      break;
    case CardLimitType.loyalty:
      canAdd = premium.canAddMoreLoyaltyCards(count);
      break;
  }

  if (!canAdd) {
    final unlocked = await showCardLimitDialog(context, type);
    if (!unlocked) return;
  }

  String route;
  switch (type) {
    case CardLimitType.credit:
      route = '/addCreditCard';
      break;
    case CardLimitType.iban:
      route = '/addIbanCard';
      break;
    case CardLimitType.loyalty:
      route = '/addLoyaltyCard';
      break;
  }
  await Get.toNamed(route);
  if (Get.isRegistered<HomeController>()) {
    Get.find<HomeController>().refreshData();
  }
}

/// Bottom sheet that lets the user pick which kind of card to add. Used by
/// the home quick-action tile and by empty-state CTAs that don't know the
/// type up front. Returns immediately after launching the chosen flow.
Future<void> showAddCardTypeSheet(BuildContext context) async {
  final colorScheme = Theme.of(context).colorScheme;
  HapticFeedback.lightImpact();
  final type = await showModalBottomSheet<CardLimitType>(
    context: context,
    backgroundColor: colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kSpaceLg,
            vertical: kSpaceMd,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: kSpaceMd),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _SheetTile(
                icon: Icons.credit_card_rounded,
                label: 'addCC'.tr(),
                accent: colorScheme.primary,
                onTap: () => Navigator.pop(sheetContext, CardLimitType.credit),
              ),
              _SheetTile(
                icon: Icons.account_balance_rounded,
                label: 'addIC'.tr(),
                accent: colorScheme.secondary,
                onTap: () => Navigator.pop(sheetContext, CardLimitType.iban),
              ),
              _SheetTile(
                icon: Icons.local_offer_rounded,
                label: 'addLC'.tr(),
                accent: colorScheme.tertiary,
                onTap: () => Navigator.pop(sheetContext, CardLimitType.loyalty),
              ),
              const SizedBox(height: kSpaceSm),
            ],
          ),
        ),
      );
    },
  );
  if (type != null && context.mounted) {
    await goToAddCard(context: context, type: type);
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _SheetTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kSpaceSm,
            vertical: kSpaceMd,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: kSpaceMd),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
