import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/dialogs/card_limit_dialog.dart';
import 'package:wallet_app/core/enums/card_limit_type.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';

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
