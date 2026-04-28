import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/feature/home/widgets/sections/add_card_tile.dart';
import 'package:wallet_app/feature/home/widgets/sections/card_carousel.dart';
import 'package:wallet_app/feature/home/widgets/sections/card_kind.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_formatters.dart';

/// One category row (CC, IBAN or Loyalty). Header + carousel (or empty
/// placeholder). Kept generic so all three shelves share a single
/// implementation — the previous body.dart copied this layout three times.
class CardShelf extends StatelessWidget {
  final HomeCardKind kind;
  final List<dynamic> cards;
  final String titleKey;
  final String addLabelKey;
  final double itemHeight;

  const CardShelf({
    Key? key,
    required this.kind,
    required this.cards,
    required this.titleKey,
    required this.addLabelKey,
    required this.itemHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = kind.accentOf(colorScheme);

    return Padding(
      padding: const EdgeInsets.only(bottom: kSpaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShelfHeader(
            title: titleKey.tr(),
            count: cards.length,
            accent: accent,
            onSeeAll: () => Get.toNamed(kind.listRoute),
          ),
          const SizedBox(height: kSpaceMd),
          if (cards.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSpaceLg),
              child: AddCardTile(
                type: kind.limitType,
                accent: accent,
                height: itemHeight,
                label: addLabelKey.tr(),
              ),
            )
          else
            CardCarousel(
              kind: kind,
              cards: cards,
              itemHeight: itemHeight,
              accent: accent,
              addLabel: addLabelKey.tr(),
            ),
        ],
      ),
    );
  }
}

class _ShelfHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color accent;
  final VoidCallback onSeeAll;

  const _ShelfHeader({
    required this.title,
    required this.count,
    required this.accent,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpaceLg),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
          ),
          if (count > 0) ...[
            const SizedBox(width: kSpaceSm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: kSpaceSm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                compactCount(count),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (count > 0)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: kSpaceSm,
                  vertical: 0,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                foregroundColor: accent,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'seeAll'.tr(),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
