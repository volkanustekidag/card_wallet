import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/constants/paddings.dart';
import 'package:wallet_app/feature/add_iban_card/widgets/iban_text_field.dart';
import 'package:wallet_app/feature/add_iban_card/widgets/text_field_card.dart';
import 'package:wallet_app/feature/add_iban_card/bloc/add_iban_card_bloc.dart';

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
    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: PaddingConstants.symmetricHighVertical(),
          child: Column(
            children: [
              TextFieldCard(
                label: "hName".tr(),
                onChanged: (val) {
                  BlocProvider.of<AddIbanCardBloc>(context).add(
                    UpdateIbanCardEvent(val, "cardHolder"),
                  );
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
                  BlocProvider.of<AddIbanCardBloc>(context).add(
                    UpdateIbanCardEvent(val, "swiftCode"),
                  );
                },
                iconData: Icons.numbers,
                hintText: "00000000",
              ),
              TextFieldCard(
                label: "bName".tr(),
                onChanged: (val) {
                  BlocProvider.of<AddIbanCardBloc>(context).add(
                    UpdateIbanCardEvent(val, "bankName"),
                  );
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
