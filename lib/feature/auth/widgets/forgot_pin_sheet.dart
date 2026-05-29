import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/controllers/auth_controller.dart';

/// Offers biometric unlock after the user has fat-fingered the PIN past the
/// first lockout threshold. Tapping "continue" runs the recovery flow on
/// [AuthController] which, on success, navigates to /home and queues a PIN
/// reset prompt there.
Future<void> showForgotPinSheet(BuildContext context) async {
  final authController = Get.find<AuthController>();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ForgotPinSheet(controller: authController),
  );
}

class _ForgotPinSheet extends StatelessWidget {
  const _ForgotPinSheet({required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final biometricName = controller.getBiometricDisplayName();
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.fingerprint,
              size: 48,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'forgotPinTitle'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'forgotPinMessage'.tr(args: [biometricName]),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.fingerprint),
              label: Text('useBiometric'.tr(args: [biometricName])),
              onPressed: () async {
                Navigator.of(context).pop();
                await controller.recoverWithBiometric();
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('cancel'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
