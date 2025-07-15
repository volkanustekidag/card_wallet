import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/constants/paddings.dart';
import 'package:wallet_app/core/controllers/add_iban_card_controller.dart';
import 'package:wallet_app/feature/add_iban_card/widgets/iban_text_field.dart';
import 'package:wallet_app/feature/add_iban_card/widgets/text_field_card.dart';

class IbanTextFieldForms extends StatelessWidget {
  const IbanTextFieldForms({
    Key? key,
    required TextEditingController ibanController,
    required this.focusNode,
    required this.cameras,
  })  : _ibanController = ibanController,
        super(key: key);

  final TextEditingController _ibanController;
  final FocusNode focusNode;
  final List<CameraDescription> cameras;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AddIbanCardController>();

    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: const PaddingConstants.symmetricHighVertical(),
          child: Column(
            children: [
              TextFieldCard(
                label: "hName".tr(),
                onChanged: (val) {
                  controller.updateCardField("cardHolder", val);
                },
                iconData: Icons.person,
                hintText: "XXXXXX XXXXXX",
              ),
              IbanTextField(
                  ibanController: _ibanController,
                  focusNode: focusNode,
                  cameras: cameras),
              TextFieldCard(
                label: "sCode".tr(),
                onChanged: (val) {
                  controller.updateCardField("swiftCode", val);
                },
                iconData: Icons.numbers,
                hintText: "00000000",
              ),
              TextFieldCard(
                label: "bName".tr(),
                onChanged: (val) {
                  controller.updateCardField("bankName", val);
                },
                iconData: Icons.account_balance_rounded,
                hintText: "XXXXXXX",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
