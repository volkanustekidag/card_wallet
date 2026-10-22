import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/controllers/auth_controller.dart';
import 'package:wallet_app/ui/components/cw_button.dart';
import 'package:wallet_app/ui/components/cw_misc.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

/// Offers biometric unlock after the user has fat-fingered the PIN past the
/// first lockout threshold. "Continue" runs the recovery flow on
/// [AuthController] which, on success, navigates to /home and queues a PIN
/// reset prompt there.
Future<void> showForgotPinSheet(BuildContext context) async {
  final controller = Get.find<AuthController>();
  final name = controller.getBiometricDisplayName();
  final go = await showCwSheet<bool>(
    context,
    builder: (sheet) {
      final c = CwColors.of(sheet);
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CwIcon(CwIcons.fingerprint, size: 40, color: c.accent),
              const SizedBox(height: 14),
              Text('forgotPinTitle'.tr(),
                  textAlign: TextAlign.center,
                  style: CwType.title.copyWith(color: c.ink, fontSize: 20)),
              const SizedBox(height: 8),
              Text('forgotPinMessage'.tr(args: [name]),
                  textAlign: TextAlign.center,
                  style: CwType.callout.copyWith(color: c.ink2, height: 1.4)),
              const SizedBox(height: 22),
              CwButton('useBiometric'.tr(args: [name]),
                  icon: CwIcons.fingerprint,
                  onPressed: () => Navigator.pop(sheet, true)),
              const SizedBox(height: 6),
              CwButton.ghost('cancel'.tr(),
                  onPressed: () => Navigator.pop(sheet, false)),
            ],
          ),
        ),
      );
    },
  );
  if (go == true) await controller.recoverWithBiometric();
}
