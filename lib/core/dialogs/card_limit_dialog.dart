import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/enums/card_limit_type.dart';
import 'package:wallet_app/core/services/premium_service.dart';

Future<bool> showCardLimitDialog(
  BuildContext rootContext,
  CardLimitType type,
) async {
  final limit = type == CardLimitType.loyalty
      ? PremiumService.maxLoyaltyCardsForFree
      : PremiumService.maxCardsForFree;
  final result = await showDialog<bool>(
    context: rootContext,
    barrierDismissible: false,
    builder: (dialogContext) {
      final navigator = Navigator.of(rootContext, rootNavigator: true);
      return AlertDialog(
        title: Text('cardLimitReachedTitle'.tr()),
        content: Text(
          'cardLimitReachedDescription'.tr(
            args: [
              limit.toString(),
              type.localizationKey.tr(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              navigator.pop(false);
            },
            child: Text('maybeLater'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              navigator.pop(false);
              Get.toNamed('/premium');
            },
            child: Text('goPremium'.tr()),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
