import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;

import 'package:sizer/sizer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/constants/paddings.dart';
import 'package:wallet_app/feature/add_credit_card/controller/add_credit_card_controller.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_number_formatter.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_valid_thru_formatter.dart';
import 'package:wallet_app/feature/add_credit_card/widgets/text_field_card.dart';

class CreditTextFieldForms extends StatelessWidget {
  const CreditTextFieldForms({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AddCreditCardController>();

    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: const PaddingConstants.normal(),
          child: Column(
            children: [
              TextFieldCard(
                  maxLength: 16,
                  onChanged: (val) {
                    controller.updateCardField("bankName", val);
                  },
                  label: "bName".tr(),
                  hintText: "XX BANK",
                  inputFormatters: null,
                  iconData: Icons.account_balance_rounded,
                  textInputType: null),
              SizedBox(height: 8),
              TextFieldCard(
                  maxLength: 19,
                  onChanged: (val) {
                    controller.updateCardField("creditCardNumber", val);
                  },
                  label: "cNum".tr(),
                  hintText: "XXXX XXXX XXXX XXXX",
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CardNumberFormatter(),
                  ],
                  iconData: Icons.numbers,
                  textInputType: TextInputType.number),
              SizedBox(height: 8),
              TextFieldCard(
                  maxLength: 24,
                  onChanged: (val) {
                    controller.updateCardField("cardHolder", val);
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
                              controller.updateCardField("expirationDate", val);
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
                            controller.updateCardField("cvc2", val);
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
