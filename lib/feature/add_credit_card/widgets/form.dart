import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/constants/paddings.dart';
import 'package:wallet_app/feature/add_credit_card/bloc/add_credit_bloc.dart';
import 'package:sizer/sizer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_number_formatter.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_valid_thru_formatter.dart';
import 'package:wallet_app/feature/add_credit_card/widgets/text_field_card.dart';

class CreditTextFieldForms extends StatelessWidget {
  const CreditTextFieldForms({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: PaddingConstants.normal(),
          child: Column(
            children: [
              TextFieldCard(
                  maxLength: 16,
                  onChanged: (val) {
                    BlocProvider.of<AddCreditBloc>(context).add(
                      UpdateCreditCardEvent(val, "bankName"),
                    );
                  },
                  label: "bName".tr(),
                  hintText: "XX BANK",
                  inputFormatters: null,
                  iconData: Icons.account_balance_rounded,
                  textInputType: null),
              TextFieldCard(
                  maxLength: 19,
                  onChanged: (val) {
                    BlocProvider.of<AddCreditBloc>(context).add(
                      UpdateCreditCardEvent(val, "creditCardNumber"),
                    );
                  },
                  label: "cNum".tr(),
                  hintText: "XXXX XXXX XXXX XXXX",
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CardNumberFormatter(),
                  ],
                  iconData: Icons.numbers,
                  textInputType: TextInputType.number),
              TextFieldCard(
                  maxLength: 24,
                  onChanged: (val) {
                    BlocProvider.of<AddCreditBloc>(context).add(
                      UpdateCreditCardEvent(val, "cardHolder"),
                    );
                  },
                  label: "hName".tr(),
                  hintText: "XXX XXXX",
                  inputFormatters: null,
                  iconData: Icons.person,
                  textInputType: null),
              SizedBox(
                width: 90.w,
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 5.0),
                        child: TextFieldCard(
                            maxLength: 5,
                            onChanged: (val) {
                              BlocProvider.of<AddCreditBloc>(context).add(
                                UpdateCreditCardEvent(val, "expirationDate"),
                              );
                            },
                            label: "valid".tr(),
                            hintText: "XX/XX",
                            inputFormatters: [CardValidThruFormatter()],
                            iconData: Icons.date_range,
                            textInputType: TextInputType.number),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5.0),
                        child: TextFieldCard(
                          maxLength: 3,
                          onChanged: (val) {
                            BlocProvider.of<AddCreditBloc>(context).add(
                              UpdateCreditCardEvent(val, "cvc2"),
                            );
                          },
                          label: "CVC2",
                          hintText: "XXX",
                          inputFormatters: null,
                          iconData: Icons.password,
                          textInputType: TextInputType.number,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
