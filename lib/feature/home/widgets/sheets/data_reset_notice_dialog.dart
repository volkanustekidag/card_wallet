import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/utils/premium_gate.dart';
import 'package:wallet_app/feature/settings/backup_restore_flow.dart';

/// Explains, once, why the wallet starts empty on this device: cards are
/// encrypted with device-only keys and don't travel with phone backups.
/// "Restore from backup" goes through the same premium gate as Settings.
Future<void> showDataResetNoticeDialog(BuildContext context) async {
  final restore = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final colorScheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        icon: Icon(
          Icons.verified_user_outlined,
          size: 40,
          color: colorScheme.primary,
        ),
        title: Text(
          'dataResetNoticeTitle'.tr(),
          textAlign: TextAlign.center,
        ),
        content: Text('dataResetNoticeBody'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('dataResetNoticeRestore'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('ok'.tr()),
          ),
        ],
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
