import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flip_card/flip_card.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/core/controllers/add_credit_card_controller.dart';
import 'package:wallet_app/core/widgets/credit_card_back.dart';
import 'package:wallet_app/core/widgets/credit_card_front.dart';
import 'package:wallet_app/feature/add_credit_card/widgets/add_credit_app_bar.dart';
import 'package:wallet_app/feature/add_credit_card/widgets/colors_list_view.dart';
import 'package:wallet_app/feature/add_credit_card/widgets/credit_form.dart';

class AddCreditCardPage extends StatefulWidget {
  const AddCreditCardPage({Key? key}) : super(key: key);

  @override
  State<AddCreditCardPage> createState() => _AddCreditCardPageState();
}

class _AddCreditCardPageState extends State<AddCreditCardPage> {
  late final AddCreditCardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AddCreditCardController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: ColorConstants.primaryColor,
      appBar: const AddCreditAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Obx(() => FlipCard(
                  direction: FlipDirection.HORIZONTAL,
                  speed: 500,
                  front: CreditCardFront(
                      creditCard: _controller.currentCard.value),
                  back:
                      CreditCardBack(creditCard: _controller.currentCard.value),
                )),
            const ColorsListView(),
            const CreditTextFieldForms(),
          ],
        ),
      ),
    );
  }
}
