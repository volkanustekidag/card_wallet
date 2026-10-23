import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wallet_app/feature/auth/pin_action_page.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/controllers/auth_controller.dart';
import 'package:wallet_app/ui/components/cw_button.dart';
import 'package:wallet_app/ui/components/cw_misc.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

/// "Forgot your PIN?": the phone's own screen lock (passcode, pattern or
/// biometrics) confirms it's the owner, then a new PIN is set right away.
/// Backing out of the new PIN still unlocks; home nudges to set one.
Future<void> showForgotPinSheet(BuildContext context) async {
  final controller = Get.find<AuthController>();
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
              CwIcon(CwIcons.unlock, size: 40, color: c.accent),
              const SizedBox(height: 14),
              Text('forgotPinTitle'.tr(),
                  textAlign: TextAlign.center,
                  style: CwType.title.copyWith(color: c.ink, fontSize: 20)),
              const SizedBox(height: 8),
              Text('cwForgotBody'.tr(),
                  textAlign: TextAlign.center,
                  style: CwType.callout.copyWith(color: c.ink2, height: 1.4)),
              const SizedBox(height: 22),
              CwButton('cwForgotUseLock'.tr(),
                  icon: CwIcons.lock,
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
  if (go != true) return;
  if (!await controller.verifyDeviceOwner()) return;
  final created = await Get.to<bool>(
    () => const PinActionPage(),
    arguments: PinAction.create,
  );
  await controller.completeRecovery(newPin: created == true);
}
