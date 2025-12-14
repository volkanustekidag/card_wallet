import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:flutter_iban_scanner/flutter_iban_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wallet_app/feature/add_iban_card/controller/add_iban_card_controller.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:easy_localization/easy_localization.dart';

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
    final premiumController = Get.find<PremiumController>();

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
            color: Colors.amber.shade600,
          ),
          onPressed: () async {
            if (!premiumController.isPremium) {
              final shouldUpgrade = await Get.dialog<bool>(
                    AlertDialog(
                      title: Text('premiumFeatureLockedTitle'.tr()),
                      content: Text('premiumFeatureLockedDescription'.tr()),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(result: false),
                          child: Text('maybeLater'.tr()),
                        ),
                        ElevatedButton(
                          onPressed: () => Get.back(result: true),
                          child: Text('goPremium'.tr()),
                        ),
                      ],
                    ),
                  ) ??
                  false;
              if (shouldUpgrade) {
                Get.toNamed('/premium');
              }
              return;
            }
            focusNode.unfocus();
            focusNode.canRequestFocus = false;

            // Kamera izni kontrol et ve iste
            final cameraStatus = await Permission.camera.status;

            if (cameraStatus.isDenied) {
              final result = await Permission.camera.request();
              if (!result.isGranted) {
                Get.snackbar(
                  'Permission Required',
                  'Camera permission is required to scan IBANs',
                  snackPosition: SnackPosition.BOTTOM,
                );
                focusNode.canRequestFocus = true;
                return;
              }
            } else if (cameraStatus.isPermanentlyDenied) {
              // İzin kalıcı olarak reddedilmiş - ayarlara yönlendir
              final shouldOpenSettings = await Get.dialog<bool>(
                AlertDialog(
                  title: Text('Camera Permission Required'),
                  content: Text(
                    'This app needs camera permission to scan IBANs. Please grant camera permission in your device settings.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(result: false),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Get.back(result: true),
                      child: Text('Open Settings'),
                    ),
                  ],
                ),
              );

              if (shouldOpenSettings == true) {
                await openAppSettings();
              }
              focusNode.canRequestFocus = true;
              return;
            }

            // İzin verildi, scanner'ı aç
            Get.to(() => IBANScannerView(
                  cameras: cameras,
                  onScannerResult: (iban) {
                    Get.back();
                    controller.updateCardField("iban", iban);
                    _ibanController.text = iban;
                  },
                ));

            Future.delayed(
              const Duration(milliseconds: 100),
              () {
                focusNode.canRequestFocus = true;
              },
            );
          },
        ),
      ),
    );
  }
}
