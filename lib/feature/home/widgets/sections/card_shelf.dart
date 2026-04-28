import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/feature/home/widgets/sections/add_card_tile.dart';
import 'package:wallet_app/feature/home/widgets/sections/card_carousel.dart';
import 'package:wallet_app/feature/home/widgets/sections/card_kind.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';

/// One category row (CC, IBAN or Loyalty). Header + carousel (or empty
/// placeholder). Header is intentionally minimal — title + a slim "see
/// all" affordance — to keep visual noise low across three repeating
/// shelves.
class CardShelf extends StatelessWidget {
  final HomeCardKind kind;
  final List<dynamic> cards;
  final String titleKey;
  final String addLabelKey;

  const CardShelf({
    Key? key,
    required this.kind,
    required this.cards,
    required this.titleKey,
    required this.addLabelKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = kind.accentOf(colorScheme);

    return Padding(
      padding: const EdgeInsets.only(bottom: kSpaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShelfHeader(
            title: titleKey.tr(),
            count: cards.length,
            accent: accent,
            onSeeAll: () => Get.toNamed(kind.listRoute),
          ),
          const SizedBox(height: kSpaceSm),
          if (cards.isEmpty)
            _EmptyShelfTile(kind: kind, accent: accent, addLabelKey: addLabelKey)
          else
            CardCarousel(
              kind: kind,
              cards: cards,
              accent: accent,
              addLabel: addLabelKey.tr(),
            ),
        ],
      ),
    );
  }
}

class _EmptyShelfTile extends StatelessWidget {
  final HomeCardKind kind;
  final Color accent;
  final String addLabelKey;
  const _EmptyShelfTile({
    required this.kind,
    required this.accent,
    required this.addLabelKey,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Mirror the carousel's geometry so the empty placeholder lines up
    // visually with non-empty shelves of the same kind.
    final pageWidth = screenWidth * kCarouselViewport;
    final cardWidth = pageWidth - kCarouselItemGap * 2;
    double aspect;
    switch (kind) {
      case HomeCardKind.credit:
        aspect = 1.586;
        break;
      case HomeCardKind.iban:
        aspect = 1.85;
        break;
      case HomeCardKind.loyalty:
        aspect = 2.6;
        break;
    }
    final cardHeight = cardWidth / aspect;

    return Center(
      child: SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: AddCardTile(
          type: kind.limitType,
          accent: accent,
          height: cardHeight,
          label: addLabelKey.tr(),
        ),
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
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: colorScheme.onSurface,
              letterSpacing: 0.1,
            ),
          ),
          const Spacer(),
          if (count > 1)
            InkWell(
              onTap: onSeeAll,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kSpaceSm,
                  vertical: kSpaceXS,
                ),
                child: Text(
                  'seeAll'.tr(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
