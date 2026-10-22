import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';
import 'package:wallet_app/feature/home/widgets/sheets/card_detail_sheet.dart';
import 'package:wallet_app/feature/loyalty_card/loyalty_card_detail_page.dart';

/// Single entry point for "open this card" from anywhere (home stack,
/// Up Next, search). Loyalty cards go straight to Checkout.
Future<void> openWalletItem(BuildContext context, WalletItem item) async {
  switch (item.kind) {
    case WalletItemKind.loyalty:
      await Get.to<void>(
        () => LoyaltyCardDetailPage(card: item.card as LoyaltyCard),
        transition: Transition.cupertino,
      );
      break;
    case WalletItemKind.credit:
    case WalletItemKind.iban:
      await showCardDetailSheet(context, item);
      break;
  }
}
