import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/controllers/home_controller.dart';
import 'package:wallet_app/feature/home/widgets/cards_list_view.dart';
import 'package:wallet_app/feature/home/widgets/dashed_empty_card.dart';
import 'package:wallet_app/feature/home/widgets/row_titles.dart';
import 'package:easy_localization/easy_localization.dart';

class HomeBody extends StatelessWidget {
  final HomeController controller;

  const HomeBody({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
          children: [
            const Spacer(),
            const RowTitles(title: "yourCC", route: "/creditCards"),
            controller.creditCards.isEmpty
                ? DashedEmptyCard(
                    text: "addFirstCC".tr(),
                    route: "/addCreditCard",
                  )
                : CardsListView(
                    list: controller.creditCards,
                    cardType: 0,
                  ),
            const Spacer(),
            const RowTitles(title: "yourIC", route: "/ibanCards"),
            controller.ibanCards.isEmpty
                ? DashedEmptyCard(
                    text: "addFirstIC".tr(),
                    route: "/addIbanCard",
                  )
                : CardsListView(
                    list: controller.ibanCards,
                    cardType: 1,
                  ),
            const Spacer(),
          ],
        ));
  }
}
