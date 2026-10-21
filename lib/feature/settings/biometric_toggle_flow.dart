import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/controllers/auth_controller.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/feature/auth/pin_action_page.dart';

/// Settings › Face ID / Touch ID / fingerprint switch. Free for every user:
/// basic security never sits behind the paywall, and nothing turns it off
/// when a subscription ends.
///
/// Biometric is a shortcut for the PIN, so enabling it without a PIN first
/// runs PIN creation ([createPin], defaults to [PinActionPage]) and stops if
/// the user backs out.
Future<void> handleBiometricToggle(
  AuthController authController,
  bool desiredValue, {
  Future<bool?> Function()? createPin,
}) async {
  HapticFeedback.lightImpact();
  if (desiredValue && !authController.hasPassword.value) {
    Get.context?.showInfoSnackBar('setupPinForBiometric');
    final created = await (createPin ?? _pushCreatePin)();
    if (created != true) return;
  }
  await authController.toggleBiometric(desiredValue);
}

Future<bool?> _pushCreatePin() async => Get.to<bool>(
      () => const PinActionPage(),
      arguments: PinAction.create,
    );
