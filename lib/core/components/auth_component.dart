import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:wallet_app/core/constants/paddings.dart';
import 'package:sizer/sizer.dart';
import 'package:easy_localization/easy_localization.dart';

class AuthViews extends StatelessWidget {
  final text;
  final onCompleted;
  const AuthViews({
    Key? key,
    required TextEditingController textEditingController,
    required this.text,
    required this.onCompleted,
  })  : _textEditingController = textEditingController,
        super(key: key);

  final TextEditingController _textEditingController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: PaddingConstants.extraHigh(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: PaddingConstants.normal(),
            child: Icon(
              Icons.lock,
              color: Colors.white,
              size: 40.sp,
            ),
          ),
          Text(
            "${text}".tr(),
            style: TextStyle(color: Colors.white, fontSize: 20.sp),
          ),
          const SizedBox(
            height: 20,
          ),
          PinCodeTextField(
            controller: _textEditingController,
            appContext: context,
            keyboardType: TextInputType.number,
            length: 4,
            obscureText: true,
            textStyle: const TextStyle(color: Colors.white),
            obscuringWidget: const Icon(Icons.circle, color: Colors.white),
            onChanged: (value) {},
            onCompleted: onCompleted,
            pinTheme: PinTheme(
                activeFillColor: Colors.white,
                shape: PinCodeFieldShape.circle,
                selectedColor: Colors.green,
                inactiveFillColor: Colors.red,
                selectedFillColor: Colors.yellow,
                activeColor: Colors.green,
                errorBorderColor: Colors.red,
                inactiveColor: Colors.white,
                disabledColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
