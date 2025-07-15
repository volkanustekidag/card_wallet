import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:flip_card/flip_card.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/controllers/credit_card_controller.dart';
import 'package:wallet_app/core/constants/paddings.dart';
import 'package:wallet_app/core/widgets/credit_card_back.dart';
import 'package:wallet_app/core/widgets/credit_card_front.dart';
import 'package:wallet_app/core/widgets/empty_list_info.dart';
import 'package:wallet_app/domain/models/credit_card_model/credit_card.dart';

class Body extends StatelessWidget {
  final CreditCardController controller;

  const Body({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const PaddingConstants.normal(),
      child: Obx(() {
        if (controller.creditCards.isEmpty) {
          return const EmptyListInfo();
        }

        return ListView(
          shrinkWrap: true,
          children: controller.creditCards
              .map<Widget>(
                (creditCard) => Slidable(
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) async {
                          controller.removeCreditCard(creditCard);
                        },
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: 'slidableDel'.tr(),
                      ),
                      SlidableAction(
                        onPressed: (context) async {
                          _generateCopyAllInfoText(creditCard);
                          Get.snackbar('Success', 'copyInfo'.tr(),
                              backgroundColor: Colors.yellow);
                        },
                        backgroundColor: Colors.yellow,
                        foregroundColor: Colors.white,
                        icon: Icons.content_copy,
                        label: 'copyAll'.tr(),
                      )
                    ],
                  ),
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
              )
              .toList(),
        );
      }),
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
