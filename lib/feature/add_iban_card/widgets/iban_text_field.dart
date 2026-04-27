import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:flutter_iban_scanner/flutter_iban_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wallet_app/feature/add_iban_card/controller/add_iban_card_controller.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/feature/add_credit_card/widgets/text_field_card.dart';

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
    final theme = Theme.of(context);
    final iconColor = premiumController.isPremium
        ? theme.colorScheme.primary
        : Colors.amber.shade700;

    return TextFieldCard(
      controller: _ibanController,
      focusNode: focusNode,
      maxLength: 35,
      label: 'IBAN',
      iconData: Icons.credit_card_rounded,
      emphasize: true,
      textStyle: TextStyle(fontFamily: 'Poppins', 
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: theme.colorScheme.onSurface,
      ),
      onChanged: (iban) => controller.updateCardField("iban", iban),
      suffixIcon: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Container(
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: IconButton(
            icon: Icon(
              Icons.camera_alt_rounded,
              color: iconColor,
              size: 18,
            ),
            tooltip: 'scanCardOptional'.tr(),
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
                final shouldOpenSettings = await Get.dialog<bool>(
                  AlertDialog(
                    title: Text('Camera Permission Required'),
                    content: const Text(
                      'This app needs camera permission to scan IBANs. Please grant camera permission in your device settings.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(result: false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Get.back(result: true),
                        child: const Text('Open Settings'),
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
      ),
    );
  }
}
