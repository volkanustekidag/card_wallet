import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:permission_handler/permission_handler.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';

class CameraPermissionService {
  const CameraPermissionService._();

  static Future<bool> ensureGranted() async {
    var status = await Permission.camera.status;

    if (status.isGranted || status.isLimited) return true;

    if (status.isDenied) {
      status = await Permission.camera.request();
      if (status.isGranted || status.isLimited) return true;
    }

    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(restricted: false);
      return false;
    }

    if (status.isRestricted) {
      await _showSettingsDialog(restricted: true);
      return false;
    }

    Get.context?.showErrorSnackBar('cameraPermissionRequired'.tr());
    return false;
  }

  static Future<void> _showSettingsDialog({required bool restricted}) async {
    if (Get.context == null) return;
    final shouldOpenSettings = await Get.dialog<bool>(
      AlertDialog(
        title: Text('cameraPermissionRequired'.tr()),
        content: Text(
          restricted
              ? 'cameraPermissionRestrictedMessage'.tr()
              : 'cameraPermissionSettingsMessage'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr()),
          ),
          if (!restricted)
            TextButton(
              onPressed: () => Get.back(result: true),
              child: Text('openSettings'.tr()),
            ),
        ],
      ),
    );
    if (shouldOpenSettings == true) {
      await openAppSettings();
    }
  }
}
