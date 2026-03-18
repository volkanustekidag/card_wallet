import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wallet_app/core/components/auth_component.dart';
import 'package:wallet_app/core/controllers/change_pin_controller.dart';
import 'package:wallet_app/feature/change_pin/widgets/app_bar.dart';

class ChangePinPage extends StatelessWidget {
  ChangePinPage({super.key});

  final TextEditingController _textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChangePinController>();

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: const ChangePinAppBar(),
      body: Obx(() {
        if (!controller.currentPinVerified.value) {
          if (controller.verificationFailed.value) {
            _textEditingController.clear();
          }

          return AuthViews(
            textEditingController: _textEditingController,
            text: "enterPin",
            onCompleted: (pin) {
              controller.verifyCurrentPin(pin);
              _textEditingController.clear();
            },
          );
        } else {
          return AuthViews(
            textEditingController: _textEditingController,
            text: "addNPIN",
            onCompleted: (pin) {
              controller.saveNewPin(pin);
            },
          );
        }
      }),
    );
  }
}
