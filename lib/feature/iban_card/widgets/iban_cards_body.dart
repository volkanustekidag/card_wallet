import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/constants/paddings.dart';
import 'package:wallet_app/core/controllers/iban_card_controller.dart';
import 'package:wallet_app/core/widgets/empty_list_info.dart';
import 'package:wallet_app/core/widgets/iban_cards.dart';
import 'package:wallet_app/domain/models/iban_card_model/iban_card.dart';

class Body extends StatelessWidget {
  final IbanCardController controller;

  const Body({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: const PaddingConstants.extraHigh(),
        child: Obx(() {
          if (controller.ibanCards.isEmpty) {
            return const EmptyListInfo();
          }

          return ListView(
            shrinkWrap: true,
            children: controller.ibanCards
                .map<Widget>(
                  (ibanCard) => Slidable(
                    endActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (context) async {
                            controller.removeIbanCard(ibanCard);
                          },
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: 'slidableDel'.tr(),
                        ),
                        SlidableAction(
                          onPressed: (context) async {
                            _generateCopyAllInfoText(ibanCard);
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
                    child: IbanCards(ibanCard: ibanCard),
                  ),
                )
                .toList(),
          );
        }),
      ),
    );
  }

  void _generateCopyAllInfoText(IbanCard ibanCard) {
    Clipboard.setData(ClipboardData(
        text:
            "${ibanCard.cardHolder}\n${ibanCard.iban}\n${ibanCard.swiftCode}\n${ibanCard.bankName}"));
  }
}
