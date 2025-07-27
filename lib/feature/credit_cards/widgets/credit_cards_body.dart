import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:flip_card/flip_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/components/dialog/delete_dialog.dart';
import 'package:wallet_app/feature/credit_cards/controller/credit_card_controller.dart';
import 'package:wallet_app/core/widgets/credit_card_back.dart';
import 'package:wallet_app/core/widgets/credit_card_front.dart';
import 'package:wallet_app/core/widgets/empty_list_info.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/feature/add_credit_card/add_credit_card_page.dart';

class Body extends StatefulWidget {
  final CreditCardController controller;

  const Body({super.key, required this.controller});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  GlobalKey<FlipCardState>? _firstCardKey;
  bool _demoShown = false;

  @override
  void initState() {
    super.initState();
    _firstCardKey = GlobalKey<FlipCardState>();
  }

  void _showFlipDemo() {
    if (_demoShown) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted &&
            _firstCardKey?.currentState != null &&
            widget.controller.creditCards.isNotEmpty) {
          // Kartı çevir
          _firstCardKey!.currentState!.toggleCard();

          // 3 saniye sonra geri çevir
          Future.delayed(Duration(milliseconds: 1500), () {
            if (mounted && _firstCardKey?.currentState != null) {
              _firstCardKey!.currentState!.toggleCard();
            }
          });

          _demoShown = true;
        }
      });
    });
  }

  // Güvenli ID kontrol metodu
  bool _shouldShowEditButton(CreditCard creditCard) {
    try {
      final idString = creditCard.id.toString();
      return idString != "1";
    } catch (e) {
      print('Error checking credit card ID: $e');
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (widget.controller.creditCards.isEmpty) {
        // Liste boşsa demo flag'ini sıfırla
        _demoShown = false;
        return const EmptyListInfo();
      }

      // Kartlar varsa ve demo henüz gösterilmediyse göster
      if (widget.controller.creditCards.isNotEmpty && !_demoShown) {
        _showFlipDemo();
      }

      return Padding(
        padding: EdgeInsets.only(top: 16.0),
        child: ListView(
          shrinkWrap: true,
          children: widget.controller.creditCards.asMap().entries.map<Widget>(
            (entry) {
              final index = entry.key;
              final creditCard = entry.value;
              final isFirstCard = index == 0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: FlipCard(
                        key: isFirstCard ? _firstCardKey : null,
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
                                () => widget.controller
                                    .removeCreditCard(creditCard),
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
                        if (_shouldShowEditButton(creditCard))
                          IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                Get.to(() => AddCreditCardPage(
                                        creditCard: creditCard))!
                                    .then((value) {
                                  widget.controller.loadCreditCards();
                                  // Edit'ten dönünce demo'yu sıfırla ki tekrar gösterilsin
                                  _demoShown = false;
                                });
                              },
                              icon: CircleAvatar(child: Icon(Icons.edit))),
                      ],
                    ),
                    SizedBox(width: 12),
                  ],
                ),
              );
            },
          ).toList(),
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
            // Silme işleminden sonra demo'yu sıfırla
            _demoShown = false;
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
