import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/feature/card_detail/bank_card_page.dart';
import 'package:wallet_app/feature/card_detail/iban_page.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';
import 'package:wallet_app/feature/loyalty_card/loyalty_card_detail_page.dart';
import 'package:wallet_app/ui/card/wallet_card_faces.dart';
import 'package:wallet_app/ui/navigation/card_expand_route.dart';

/// Single entry point for "open this card" from anywhere (home stack,
/// Up Next, search, lists). Loyalty cards go straight to Checkout, growing
/// out of the card (or row) [context] belongs to.
Future<void> openWalletItem(BuildContext context, WalletItem item) async {
  switch (item.kind) {
    case WalletItemKind.loyalty:
      await Navigator.of(context).push(CardExpandRoute<void>(
        origin: originRectOf(context),
        material: materialForItem(item),
        builder: (_) => LoyaltyCardDetailPage(card: item.card as LoyaltyCard),
      ));
      break;
    case WalletItemKind.credit:
      await Get.to<void>(
        () => BankCardPage(card: item.card as CreditCard),
        transition: Transition.cupertino,
      );
      break;
    case WalletItemKind.iban:
      await Get.to<void>(
        () => IbanPage(card: item.card as IbanCard),
        transition: Transition.cupertino,
      );
      break;
  }
}
