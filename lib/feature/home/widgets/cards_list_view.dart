import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:wallet_app/core/widgets/iban_cards.dart';
import 'package:wallet_app/core/widgets/mini_credit_card.dart';

class CardsListView extends StatelessWidget {
  final List list;
  final cardType;

  const CardsListView({
    Key? key,
    required this.list,
    required this.cardType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28.h,
      child: ListView.builder(
        itemCount: list.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return SizedBox(
              height: 20.h,
              width: 90.w,
              child: cardType == 0
                  ? MiniCreditCard(creditCard: list[index])
                  : IbanCards(ibanCard: list[index]));
        },
      ),
    );
  }
}
