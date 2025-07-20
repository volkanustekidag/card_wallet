import 'package:flutter/material.dart';
import 'package:wallet_app/core/widgets/iban_card_widget.dart';
import 'package:wallet_app/core/widgets/mini_credit_card.dart';
import 'package:get/get.dart';

class CardsListView extends StatefulWidget {
  final List list;
  final int cardType;

  const CardsListView({
    Key? key,
    required this.list,
    required this.cardType,
  }) : super(key: key);

  @override
  State<CardsListView> createState() => _CardsListViewState();
}

class _CardsListViewState extends State<CardsListView> {
  late PageController _pageController;
  double currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.82)
      ..addListener(() {
        setState(() {
          currentPage = _pageController.page ?? 0;
        });
      });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.cardType == 0 ? Get.height * 0.3 : Get.height * 0.23,
      child: PageView.builder(
        clipBehavior: Clip.none,
        controller: _pageController,
        itemCount: widget.list.length,
        itemBuilder: (context, index) {
          double scale = (1 - (currentPage - index).abs()).clamp(0.85, 1.0);
          return TweenAnimationBuilder(
            duration: Duration(milliseconds: 200),
            tween: Tween<double>(begin: scale, end: scale),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 0),
                  child: widget.cardType == 0
                      ? MiniCreditCard(creditCard: widget.list[index])
                      : IbanCardWidget(ibanCard: widget.list[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
