import 'package:flutter/material.dart';
import 'package:wallet_app/core/enums/card_limit_type.dart';

/// Discriminator for the three card categories rendered on the home shelves.
/// Holds the wiring needed by CardShelf and CardCarousel without dragging
/// in the limit-type API everywhere.
enum HomeCardKind {
  credit('credit', '/creditCards', '/addCreditCard', CardLimitType.credit),
  iban('iban', '/ibanCards', '/addIbanCard', CardLimitType.iban),
  loyalty('loyalty', '/loyaltyCards', '/addLoyaltyCard', CardLimitType.loyalty);

  final String tag;
  final String listRoute;
  final String addRoute;
  final CardLimitType limitType;
  const HomeCardKind(this.tag, this.listRoute, this.addRoute, this.limitType);
}

extension HomeCardKindAccent on HomeCardKind {
  Color accentOf(ColorScheme scheme) {
    switch (this) {
      case HomeCardKind.credit:
        return scheme.primary;
      case HomeCardKind.iban:
        return scheme.secondary;
      case HomeCardKind.loyalty:
        return scheme.tertiary;
    }
  }
}
