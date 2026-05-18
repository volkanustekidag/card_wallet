import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wallet_app/feature/add_iban_card/controller/add_iban_card_controller.dart';
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
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.primary;

    return Obx(() {
      final ibanValue = controller.currentCard.value.iban;
      return TextFieldCard(
        controller: _ibanController,
        focusNode: focusNode,
        maxLength: 35,
        label: 'IBAN',
        iconData: Icons.credit_card_rounded,
        emphasize: true,
        errorText: _ibanError(ibanValue),
        textStyle: TextStyle(
          fontFamily: 'Poppins',
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
                focusNode.unfocus();
                focusNode.canRequestFocus = false;
                await _scanIbanFromCamera(
                  controller: controller,
                  focusNode: focusNode,
                );
              },
            ),
          ),
        ),
      );
    });
  }

  String? _ibanError(String value) {
    final cleaned = value.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    if (cleaned.isEmpty) return null;
    if (cleaned.length < 4) return null;
    if (!RegExp(r'^[A-Z]{2}[0-9]{2}').hasMatch(cleaned)) {
      return 'ibanInvalidFormat'.tr();
    }
    if (cleaned.length < 15) return 'ibanTooShortError'.tr();
    if (cleaned.length > 34) return 'ibanTooLongError'.tr();
    return null;
  }

  Future<void> _scanIbanFromCamera({
    required AddIbanCardController controller,
    required FocusNode focusNode,
  }) async {
    try {
      final allowed = await _ensureCameraPermission();
      if (!allowed) return;

      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
      );
      if (picked == null) return;

      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      try {
        final recognized = await recognizer.processImage(
          InputImage.fromFilePath(picked.path),
        );
        final iban = _extractIban(recognized.text);
        if (iban == null) {
          final ctx = Get.context;
          if (ctx != null) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text('IBAN bulunamadı'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }
        controller.updateCardField("iban", iban);
        _ibanController.text = iban;
      } finally {
        await recognizer.close();
      }
    } finally {
      focusNode.canRequestFocus = true;
    }
  }

  Future<bool> _ensureCameraPermission() async {
    final cameraStatus = await Permission.camera.status;

    if (cameraStatus.isDenied) {
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        final ctx = Get.context;
        if (ctx != null) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text('cameraPermissionRequired'.tr()),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return false;
      }
    } else if (cameraStatus.isPermanentlyDenied) {
      final shouldOpenSettings = await Get.dialog<bool>(
        AlertDialog(
          title: Text('cameraPermissionRequired'.tr()),
          content: const Text(
            'This app needs camera permission to scan IBANs. Please grant camera permission in your device settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('cancel'.tr()),
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
      return false;
    }

    return true;
  }

  String? _extractIban(String text) {
    final normalized = text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final match = RegExp(r'[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}').firstMatch(
      normalized,
    );
    if (match == null) return null;
    final raw = match.group(0)!;
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(raw[i]);
    }
    return buffer.toString();
  }
}
