import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wallet_app/core/enums/card_limit_type.dart';
import 'package:wallet_app/core/widgets/lifted_surface.dart';
import 'package:wallet_app/feature/home/widgets/sections/add_card_navigator.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';

/// Sentinel "+" tile shown either as the last item of a card carousel or
/// as the standalone placeholder when a category is empty. Replaces the
/// old DashedEmptyCard while reusing its premium-limit gating through
/// goToAddCard.
class AddCardTile extends StatelessWidget {
  final CardLimitType type;
  final Color accent;
  final double height;
  final String label;

  const AddCardTile({
    Key? key,
    required this.type,
    required this.accent,
    required this.height,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kCarouselItemGap),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => goToAddCard(context: context, type: type),
          child: SizedBox(
            height: height,
            child: LiftedSurface(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.04),
                  accent.withValues(alpha: 0.12),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: accent.withValues(alpha: 0.3),
                width: 1.4,
              ),
              child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: accent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: kSpaceMd),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: kSpaceXS),
                  Text(
                    'tapToAdd'.tr(),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }
}
