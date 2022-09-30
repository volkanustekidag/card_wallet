import 'package:wallet_app/core/constants/paddings.dart';
import 'package:wallet_app/core/widgets/empty_list_info.dart';
import 'package:wallet_app/core/widgets/iban_cards.dart';
import 'package:wallet_app/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/feature/iban_card/bloc/iban_card_bloc.dart';
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
    return Container(
      child: Padding(
        padding: const PaddingConstants.extraHigh(),
        child: state.ibanCardList.isEmpty
            ? EmptyListInfo()
            : ListView(
                shrinkWrap: true,
                children: state.ibanCardList
                    .map<Widget>(
                      (ibanCard) => Slidable(
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) async {
                                BlocProvider.of<IbanCardBloc>(context)
                                    .add(RemoveIbanCardsEvent(ibanCard));

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
                                _generateCopyAllInfoText(ibanCard);
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
                        child: IbanCards(ibanCard: ibanCard),
                      ),
                    )
                    .toList(),
              ),
      ),
    );
  }

  void _generateCopyAllInfoText(IbanCard ibanCard) {
    Clipboard.setData(ClipboardData(
        text:
            "${ibanCard.cardHolder}\n${ibanCard.iban}\n${ibanCard.swiftCode}\n${ibanCard.bankName}"));
    ;
  }
}
