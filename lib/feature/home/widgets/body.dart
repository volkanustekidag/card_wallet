import 'package:flutter/material.dart';
import 'package:wallet_app/feature/home/widgets/cards_list_view.dart';
import 'package:wallet_app/feature/home/widgets/dashed_empty_card.dart';
import 'package:wallet_app/feature/home/widgets/row_titles.dart';
import 'package:easy_localization/easy_localization.dart';

class HomeBody extends StatelessWidget {
  final state;
  const HomeBody({
    Key? key,
    required this.state,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        RowTitles(title: "yourCC", route: "creditCards"),
        state.creditCardList.isEmpty
            ? DashedEmptyCard(
                text: "addFirstCC".tr(),
                route: "addCreditCard",
              )
            : CardsListView(
                list: state.creditCardList,
                cardType: 0,
              ),
        const Spacer(),
        RowTitles(title: "yourIC", route: "ibanCards"),
        state.ibanCardList.isEmpty
            ? DashedEmptyCard(
                text: "addFirstIC".tr(),
                route: "addIbanCard",
              )
            : CardsListView(
                list: state.ibanCardList,
                cardType: 1,
              ),
        const Spacer(),
      ],
    );
  }
}
