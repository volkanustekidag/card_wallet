// ignore_for_file: avoid_renaming_method_parameters

import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/core/widgets/credit_card_back.dart';
import 'package:wallet_app/core/widgets/credit_card_front.dart';
import 'package:wallet_app/feature/add_credit_card/bloc/add_credit_bloc.dart';

import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/feature/add_credit_card/widgets/app_bar.dart';
import 'package:wallet_app/feature/add_credit_card/widgets/colors_list_view.dart';
import 'package:wallet_app/feature/add_credit_card/widgets/form.dart';

class AddCreditCard extends StatefulWidget {
  const AddCreditCard({Key? key}) : super(key: key);

  @override
  State<AddCreditCard> createState() => _AddCreditCardState();
}

class _AddCreditCardState extends State<AddCreditCard> {
  bool checkBuilderState(state) => state is SaveCreditCardState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: ColorConstants.primaryColor,
      appBar: AddCreditAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            BlocConsumer<AddCreditBloc, AddCreditState>(
              listener: (context, state) {
                if (state is UpdadeCreditCardState) {
                  BlocProvider.of<AddCreditBloc>(context).add(
                    SaveCreditCardEvent(state.creditCard),
                  );
                }
              },
              builder: (context, state) {
                if (state is SaveCreditCardState) {
                  return FlipCard(
                    direction: FlipDirection.HORIZONTAL,
                    speed: 500,
                    front: CreditCardFront(creditCard: state.creditCard),
                    back: CreditCardBack(creditCard: state.creditCard),
                  );
                }
                return Container();
              },
            ),
            ColorsListView(),
            CreditTextFieldForms()
          ],
        ),
      ),
    );
  }
}
