import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/utils/premium_gate.dart';
import 'package:wallet_app/feature/settings/backup_restore_flow.dart';
import 'package:wallet_app/ui/components/cw_button.dart';
import 'package:wallet_app/ui/components/cw_misc.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

/// Explains, once, why the wallet starts empty on this device: cards are
/// encrypted with device-only keys and don't travel with phone backups.
/// "Restore from backup" goes through the same premium gate as Settings.
Future<void> showDataResetNoticeDialog(BuildContext context) async {
  final restore = await showCwSheet<bool>(
    context,
    builder: (sheet) {
      final c = CwColors.of(sheet);
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: c.bg,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: CwElevation.e1(sheet),
                  ),
                  alignment: Alignment.center,
                  child: CwIcon(CwIcons.phone, size: 32, color: c.ink),
                ),
              ),
              const SizedBox(height: 16),
              Text('cwNewPhoneTitle'.tr(),
                  textAlign: TextAlign.center,
                  style: CwType.title.copyWith(color: c.ink)),
              const SizedBox(height: 8),
              Text('cwNewPhoneBody'.tr(),
                  textAlign: TextAlign.center,
                  style: CwType.callout.copyWith(color: c.ink2, height: 1.45)),
              const SizedBox(height: 22),
              CwButton('dataResetNoticeRestore'.tr(),
                  onPressed: () => Navigator.pop(sheet, true)),
              const SizedBox(height: 6),
              CwButton.ghost('cwStartFresh'.tr(),
                  onPressed: () => Navigator.pop(sheet, false)),
            ],
          ),
        ),
      );
    },
  );
  if (restore != true || !context.mounted) return;

  final isPremium = Get.isRegistered<PremiumController>() &&
      Get.find<PremiumController>().isPremium;
  if (isPremium) {
    await restoreFromBackupFlow(context);
  } else {
    await openPremiumGate('backupRestore');
  }
}
