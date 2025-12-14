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
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/router/getx_bindings.dart';

class Body extends StatefulWidget {
  final CreditCardController controller;

  const Body({super.key, required this.controller});

  @override
  State<Body> createState() => _BodyState();
}

enum _DemoStage { idle, flippingToBack, showingBack, flippingToFront }

class _BodyState extends State<Body> {
  GlobalKey<FlipCardState>? _firstCardKey;
  bool _demoShown = false;
  _DemoStage _demoStage = _DemoStage.idle;

  @override
  void initState() {
    super.initState();
    _firstCardKey = GlobalKey<FlipCardState>();
  }

  void _resetDemoState() {
    _demoShown = false;
    _demoStage = _DemoStage.idle;
    _firstCardKey = GlobalKey<FlipCardState>();
  }

  void _scheduleFlipDemo() {
    if (_demoShown || _demoStage != _DemoStage.idle || _firstCardKey == null) {
      return;
    }
    _demoStage = _DemoStage.flippingToBack;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cardState = _firstCardKey?.currentState;
      if (!_canAnimate(cardState)) {
        _demoStage = _DemoStage.idle;
        return;
      }

      if (!cardState!.isFront) {
        cardState.toggleCardWithoutAnimation();
      }

      Future.delayed(const Duration(milliseconds: _initialDelayMs), () {
        final state = _firstCardKey?.currentState;
        if (!_canAnimate(state) || _demoStage != _DemoStage.flippingToBack) {
          _demoStage = _DemoStage.idle;
          return;
        }
        state!.toggleCard();
      });
    });
  }

  bool _canAnimate(FlipCardState? cardState) {
    if (!mounted || cardState == null) return false;
    return cardState.mounted;
  }

  static const int _initialDelayMs = 400;
  static const int _backHoldDurationMs = 800;

  void _handleDemoFlip(bool wasFrontBeforeFlip) {
    if (_firstCardKey?.currentState == null) {
      _demoStage = _DemoStage.idle;
      return;
    }

    final showingBack = wasFrontBeforeFlip;

    if (_demoStage == _DemoStage.flippingToBack && showingBack) {
      _demoStage = _DemoStage.showingBack;
      Future.delayed(const Duration(milliseconds: _backHoldDurationMs), () {
        if (_demoStage != _DemoStage.showingBack) return;
        final state = _firstCardKey?.currentState;
        if (!_canAnimate(state)) {
          _demoStage = _DemoStage.idle;
          return;
        }
        _demoStage = _DemoStage.flippingToFront;
        state!.toggleCard();
      });
    } else if (_demoStage == _DemoStage.flippingToFront && !showingBack) {
      _demoStage = _DemoStage.idle;
      _demoShown = true;
    }
  }

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
      final cards = widget.controller.creditCards;

      if (cards.isEmpty) {
        _resetDemoState();
        return const EmptyListInfo();
      }

      _firstCardKey ??= GlobalKey<FlipCardState>();
      _scheduleFlipDemo();

      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final creditCard = cards[index];
          final isFirstCard = index == 0;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: FlipCard(
                    key: isFirstCard ? _firstCardKey : null,
                    direction: FlipDirection.HORIZONTAL,
                    speed: 1000,
                    onFlipDone: isFirstCard ? _handleDemoFlip : null,
                    back: CreditCardBack(creditCard: creditCard),
                    front: CreditCardFront(creditCard: creditCard),
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        showDialogDeleteData(
                          context,
                          () => widget.controller.removeCreditCard(creditCard),
                        );
                      },
                      icon: const CircleAvatar(child: Icon(Icons.delete)),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        _generateCopyAllInfoText(creditCard);
                        context.showSuccessSnackBar('copyInfo');
                      },
                      icon: const CircleAvatar(child: Icon(Icons.copy)),
                    ),
                    if (_shouldShowEditButton(creditCard))
                      IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          Get.to(
                            () => AddCreditCardPage(creditCard: creditCard),
                            binding: AddCreditCardBindings(),
                          )!.then((value) {
                            widget.controller.loadCreditCards();
                            _resetDemoState();
                          });
                        },
                        icon: const CircleAvatar(child: Icon(Icons.edit)),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
              ],
            ),
          );
        },
      );
    });
  }

  Future<void> showDialogDeleteData(
      BuildContext context, Function onConfirm) async {
    showDialog(
      context: context,
      builder: (context) {
        return CustomDialog(
          title: 'deleteCreditCard'.tr(),
          content: 'deleteDataMessage'.tr(),
          onConfirm: () async {
            await onConfirm();
            Get.back();
            _resetDemoState();
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
