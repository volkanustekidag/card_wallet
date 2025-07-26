import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_iban_scanner/flutter_iban_scanner.dart';
import 'package:wallet_app/feature/add_iban_card/controller/add_iban_card_controller.dart';

class IbanTextField extends StatelessWidget {
  const IbanTextField({
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

    return TextField(
      maxLength: 35,
      controller: _ibanController,
      onChanged: (iban) {
        controller.updateCardField("iban", iban);
      },
      focusNode: focusNode,
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.numbers,
        ),
        labelText: "IBAN",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(width: 1),
        ),
        hintText: '',
        suffixIcon: IconButton(
          icon: Icon(
            Icons.camera_alt,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () => {
            focusNode.unfocus(),
            focusNode.canRequestFocus = false,
            Get.to(() => IBANScannerView(
                  cameras: cameras,
                  onScannerResult: (iban) {
                    Get.back();
                    controller.updateCardField("iban", iban);
                    _ibanController.text = iban;
                  },
                )),
            Future.delayed(
              const Duration(milliseconds: 100),
              () {
                focusNode.canRequestFocus = true;
              },
            ),
          },
        ),
      ),
    );
  }
}
