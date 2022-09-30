import 'package:wallet_app/core/constants/paddings.dart';
import 'package:wallet_app/core/widgets/credit_card_back.dart';
import 'package:wallet_app/core/widgets/credit_card_front.dart';
import 'package:wallet_app/core/widgets/empty_list_info.dart';
import 'package:wallet_app/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/feature/credit_cards/bloc/credit_card_bloc.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';

class Body extends StatelessWidget {
  final state;
  const Body({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: PaddingConstants.normal(),
      child: state.creditCardList.isEmpty
          ? EmptyListInfo()
          : ListView(
              shrinkWrap: true,
              children: state.creditCardList
                  .map<Widget>(
                    (creditCard) => Slidable(
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (context) async {
                              BlocProvider.of<CreditCardBloc>(context)
                                  .add(RemoveCreditCardsEvent(creditCard));

                              context.showSnackBarInfo(
                                  context, Colors.green, "cardDeleteInfo");
                            },
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'slidableDel'.tr(),
                          ),
                          SlidableAction(
                            onPressed: (context) async {
                              _generateCopyAllInfoText(creditCard);
                              context.showSnackBarInfo(
                                  context, Colors.yellow, "copyInfo");
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
            ),
    );
  }
}

void _generateCopyAllInfoText(CreditCard creditCard) {
  Clipboard.setData(
    ClipboardData(
        text:
            "${creditCard.bankName}\n${creditCard.creditCardNumber}\n${creditCard.cardHolder}\n${creditCard.expirationDate}\n${creditCard.cvc2}"),
  );
}
