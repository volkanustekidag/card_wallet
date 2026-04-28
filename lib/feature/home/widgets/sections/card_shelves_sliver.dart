import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/feature/home/widgets/sections/card_kind.dart';
import 'package:wallet_app/feature/home/widgets/sections/card_shelf.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';

/// Three card-category shelves stacked vertically inside the home scroll
/// view. The order is fixed (CC → IBAN → Loyalty) and each shelf is
/// generic — the only thing that changes is data + accent.
class CardShelvesSliver extends StatelessWidget {
  final HomeController controller;
  const CardShelvesSliver({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cc = controller.creditCards.toList();
      final iban = controller.ibanCards.toList();
      final loyalty = controller.loyaltyCards.toList();

      return SliverList(
        delegate: SliverChildListDelegate.fixed([
          const SizedBox(height: kSpaceMd),
          CardShelf(
            kind: HomeCardKind.credit,
            cards: cc,
            titleKey: 'lastAddedCreditCard',
            addLabelKey: 'addCC',
            itemHeight: kCcCarouselHeight,
          ),
          CardShelf(
            kind: HomeCardKind.iban,
            cards: iban,
            titleKey: 'lastAddedIbanCard',
            addLabelKey: 'addIC',
            itemHeight: kIbanCarouselHeight,
          ),
          CardShelf(
            kind: HomeCardKind.loyalty,
            cards: loyalty,
            titleKey: 'lastAddedLoyaltyCard',
            addLabelKey: 'addLC',
            itemHeight: kLoyaltyCarouselHeight,
          ),
        ]),
      );
    });
  }
}
