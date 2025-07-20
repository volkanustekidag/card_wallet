import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:flip_card/flip_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/components/dialog/delete_dialog.dart';
import 'package:wallet_app/core/controllers/credit_card_controller.dart';
import 'package:wallet_app/core/widgets/credit_card_back.dart';
import 'package:wallet_app/core/widgets/credit_card_front.dart';
import 'package:wallet_app/core/widgets/empty_list_info.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';

class Body extends StatelessWidget {
  final CreditCardController controller;

  const Body({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    print("object");
    return Obx(() {
      if (controller.creditCards.isEmpty) {
        return const EmptyListInfo();
      }

      return Padding(
        padding: EdgeInsets.only(top: 16.0),
        child: ListView(
          shrinkWrap: true,
          children: controller.creditCards
              .map<Widget>(
                (creditCard) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: FlipCard(
                          direction: FlipDirection.HORIZONTAL,
                          speed: 1000,
                          onFlipDone: (status) {},
                          back: CreditCardBack(creditCard: creditCard),
                          front: CreditCardFront(
                            creditCard: creditCard,
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                showDialogDeleteData(
                                  context,
                                  () => controller.removeCreditCard(creditCard),
                                );
                              },
                              icon: CircleAvatar(child: Icon(Icons.delete))),
                          IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                _generateCopyAllInfoText(creditCard);
                                Get.snackbar('Success', 'copyInfo'.tr(),
                                    backgroundColor: Colors.yellow);
                              },
                              icon: CircleAvatar(child: Icon(Icons.copy))),
                          if (creditCard.id != 1)
                            IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {},
                                icon: CircleAvatar(child: Icon(Icons.edit))),
                        ],
                      ),
                      SizedBox(width: 12),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      );
    });
  }

  Future<void> showDialogDeleteData(
      BuildContext context, Function onConfirm) async {
    showDialog(
      context: context,
      builder: (context) {
        return CustomDialog(
          onConfirm: () async {
            await onConfirm();
            Get.back();
          },
        );
      },
    );
  }

  void _generateCopyAllInfoText(CreditCard creditCard) {
    Clipboard.setData(
      ClipboardData(
          text:
              "${creditCard.bankName}\n${creditCard.creditCardNumber}\n${creditCard.cardHolder}\n${creditCard.expirationDate}\n${creditCard.cvc2}"),
    );
  }
}
