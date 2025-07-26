import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flip_card/flip_card.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/widgets/credit_card_back.dart';
import 'package:wallet_app/core/widgets/credit_card_front.dart';
import 'package:wallet_app/feature/add_credit_card/controller/add_credit_card_controller.dart';
import 'package:wallet_app/feature/add_credit_card/widgets/add_credit_app_bar.dart';
import 'package:wallet_app/feature/add_credit_card/widgets/colors_list_view.dart';
import 'package:wallet_app/feature/add_credit_card/widgets/credit_form.dart';

class AddCreditCardPage extends StatefulWidget {
  final CreditCard? creditCard; // Opsiyonel parametresi

  const AddCreditCardPage({Key? key, this.creditCard}) : super(key: key);

  @override
  State<AddCreditCardPage> createState() => _AddCreditCardPageState();
}

class _AddCreditCardPageState extends State<AddCreditCardPage> {
  late final AddCreditCardController _controller =
      Get.put(AddCreditCardController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AddCreditAppBar(creditCard: widget.creditCard),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 24),
            Obx(
              () => FlipCard(
                direction: FlipDirection.HORIZONTAL,
                speed: 500,
                front:
                    CreditCardFront(creditCard: _controller.currentCard.value),
                back: CreditCardBack(creditCard: _controller.currentCard.value),
              ),
            ),
            SizedBox(height: 16),
            const ColorsListView(),
            SizedBox(height: 16),
            const CreditTextFieldForms(),
          ],
        ),
      ),
    );
  }
}
