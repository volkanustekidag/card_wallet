import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/utils/card_sorting.dart';
import 'package:wallet_app/core/widgets/credit_card_front.dart';
import 'package:wallet_app/core/widgets/mini_iban_card_widget.dart';
import 'package:wallet_app/feature/home/widgets/sections/add_card_tile.dart';
import 'package:wallet_app/feature/home/widgets/sections/card_kind.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';
import 'package:wallet_app/feature/loyalty_card/widgets/loyalty_card_widget.dart';

/// Horizontal snap carousel for one card category. PageView with
/// viewportFraction = kCarouselViewport gives that Apple-Wallet peek;
/// width and height are both derived from the actual screen width so
/// the cards never overflow on small phones or shrink on tablets.
class CardCarousel extends StatefulWidget {
  final HomeCardKind kind;
  final List<dynamic> cards;
  final Color accent;
  final String addLabel;

  const CardCarousel({
    Key? key,
    required this.kind,
    required this.cards,
    required this.accent,
    required this.addLabel,
  }) : super(key: key);

  @override
  State<CardCarousel> createState() => _CardCarouselState();
}

class _CardCarouselState extends State<CardCarousel> {
  late final PageController _controller;
  int _index = 0;

  static const int _maxCards = 5;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: kCarouselViewport);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<dynamic> _sortedCards() {
    final list = [...widget.cards];
    list.sort((a, b) => compareNewestFirst(
          aCreatedAt: _createdAt(a),
          aId: _id(a),
          bCreatedAt: _createdAt(b),
          bId: _id(b),
        ));
    return list.take(_maxCards).toList();
  }

  DateTime? _createdAt(dynamic card) {
    if (card is CreditCard) return card.createdAt;
    if (card is IbanCard) return card.createdAt;
    if (card is LoyaltyCard) return card.createdAt;
    return null;
  }

  dynamic _id(dynamic card) {
    if (card is CreditCard) return card.id;
    if (card is IbanCard) return card.id;
    if (card is LoyaltyCard) return card.id;
    return '';
  }

  /// Aspect ratio (width / height) per kind. CC matches the ISO 7810
  /// 1.586 ratio, IBAN slimmer, loyalty wider/shorter so the wallet
  /// feels mixed-media instead of three identical boxes.
  double _aspectFor(HomeCardKind kind) {
    switch (kind) {
      case HomeCardKind.credit:
        return 1.586;
      case HomeCardKind.iban:
        return 1.85;
      case HomeCardKind.loyalty:
        return 2.6;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = _sortedCards();
    final itemCount = cards.length + 1; // +1 for the AddCardTile sentinel

    final screenWidth = MediaQuery.of(context).size.width;
    final pageWidth = screenWidth * kCarouselViewport;
    final cardWidth = pageWidth - kCarouselItemGap * 2;
    final cardHeight = cardWidth / _aspectFor(widget.kind);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: cardHeight,
          child: PageView.builder(
            controller: _controller,
            physics: const PageScrollPhysics(),
            padEnds: true,
            itemCount: itemCount,
            onPageChanged: (i) {
              HapticFeedback.selectionClick();
              setState(() => _index = i);
            },
            itemBuilder: (context, index) {
              if (index == itemCount - 1) {
                return AddCardTile(
                  type: widget.kind.limitType,
                  accent: widget.accent,
                  height: cardHeight,
                  label: widget.addLabel,
                );
              }
              return _buildCardItem(
                context,
                cards[index],
                cardWidth: cardWidth,
                cardHeight: cardHeight,
              );
            },
          ),
        ),
        if (itemCount > 1) ...[
          const SizedBox(height: kSpaceSm),
          _CarouselDots(
            count: itemCount,
            activeIndex: _index,
            accent: widget.accent,
          ),
        ],
      ],
    );
  }

  Widget _buildCardItem(
    BuildContext context,
    dynamic card, {
    required double cardWidth,
    required double cardHeight,
  }) {
    switch (widget.kind) {
      case HomeCardKind.credit:
        return _CarouselFrame(
          tag: 'home-card-credit-${(card as CreditCard).id}',
          onTap: () => Get.toNamed(widget.kind.listRoute),
          child: SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: CreditCardFront(creditCard: card),
          ),
        );
      case HomeCardKind.iban:
        return _CarouselFrame(
          tag: 'home-card-iban-${(card as IbanCard).id}',
          onTap: () => Get.toNamed(widget.kind.listRoute),
          child: MiniIbanCardWidget(
            ibanCard: card,
            onTap: () => Get.toNamed(widget.kind.listRoute),
            onLongPress: () => Get.toNamed(widget.kind.listRoute),
          ),
        );
      case HomeCardKind.loyalty:
        return _CarouselFrame(
          tag: 'home-card-loyalty-${(card as LoyaltyCard).id}',
          onTap: () => Get.toNamed(widget.kind.listRoute),
          child: LoyaltyCardWidget(card: card),
        );
    }
  }
}

class _CarouselFrame extends StatelessWidget {
  final String tag;
  final Widget child;
  final VoidCallback onTap;

  const _CarouselFrame({
    required this.tag,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kCarouselItemGap),
      child: GestureDetector(
        onTap: onTap,
        child: Hero(
          tag: tag,
          createRectTween: (begin, end) =>
              MaterialRectArcTween(begin: begin, end: end),
          child: Material(
            color: Colors.transparent,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _CarouselDots extends StatelessWidget {
  final int count;
  final int activeIndex;
  final Color accent;

  const _CarouselDots({
    required this.count,
    required this.activeIndex,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return AnimatedContainer(
          duration: kMediumAnim,
          curve: kHomeCurve,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? kCarouselDotActiveWidth : kCarouselDotSize,
          height: kCarouselDotSize,
          decoration: BoxDecoration(
            color: active
                ? accent
                : colorScheme.onSurface.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(kCarouselDotSize),
          ),
        );
      }),
    );
  }
}
