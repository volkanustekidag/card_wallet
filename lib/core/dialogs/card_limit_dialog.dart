import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/enums/card_limit_type.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';

Future<bool> showCardLimitDialog(
  BuildContext rootContext,
  CardLimitType type,
) async {
  final premiumController = Get.find<PremiumController>();

  final result = await showDialog<bool>(
    context: rootContext,
    barrierDismissible: false,
    builder: (dialogContext) {
      bool isLoading = false;
      return StatefulBuilder(
        builder: (context, setState) {
          final navigator = Navigator.of(rootContext, rootNavigator: true);
          return AlertDialog(
            title: Text('cardLimitReachedTitle'.tr()),
            content: Text(
              'cardLimitReachedDescription'.tr(
                args: [type.localizationKey.tr()],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        navigator.pop(false);
                        Get.toNamed('/premium');
                      },
                child: Text('goPremium'.tr()),
              ),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        navigator.pop(false);
                      },
                child: Text('maybeLater'.tr()),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        setState(() => isLoading = true);
                        final rewarded =
                            await premiumController.requestRewardedSlot(type);
                        setState(() => isLoading = false);

                        if (rewarded) {
                          rootContext
                              .showSuccessSnackBar('rewardedAdSuccess');
                          navigator.pop(true);
                        } else {
                          rootContext.showErrorSnackBar('rewardedAdFailed');
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('watchRewardedAd'.tr()),
              ),
            ],
          );
        },
      );
    },
  );

  return result ?? false;
}
