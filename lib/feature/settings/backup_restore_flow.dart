import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/data/services/backup_service.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/services/analytics_service.dart';
import 'package:wallet_app/core/services/error_reporter.dart';

/// Settings › Restore: confirm, pick the file, ask for its password and
/// replace the wallet. Also started from the home "cards stay on this
/// device" notice. Callers handle the premium gate.
Future<void> restoreFromBackupFlow(BuildContext context) async {
  final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: Text('restoreTitle'.tr()),
          content: Text('restoreContent'.tr()),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              child: Text('confirm'.tr()),
            ),
          ],
        ),
      ) ??
      false;
  if (!confirmed) return;

  try {
    final backupService = BackupService();
    final restored = await backupService.restoreFromFile(
      passwordProvider: () async => promptBackupPassword(
        Get.context ?? context,
        title: 'restorePasswordTitle'.tr(),
        description: 'restorePasswordDescription'.tr(),
        confirmRequired: false,
      ),
      confirmLegacyPlaintext: _confirmLegacyPlaintextRestore,
    );
    if (!restored) return;
    AnalyticsService.instance.logBackupRestored();
    if (!context.mounted) return;
    context.showSuccessSnackBar('restoreSuccess');
  } on BackupError catch (e) {
    if (!context.mounted) return;
    context.showErrorSnackBar(localizeBackupError(e));
  } catch (e, st) {
    ErrorReporter.report(e, st, reason: 'restoreBackup');
    if (!context.mounted) return;
    context.showErrorSnackBar('restoreError');
  }
}

/// v1.0 backups are plain JSON: anyone holding the file can read the card
/// numbers. Make the user acknowledge that before restoring one.
Future<bool> _confirmLegacyPlaintextRestore() async {
  final result = await Get.dialog<bool>(
    AlertDialog(
      title: Text('legacyBackupWarningTitle'.tr()),
      content: Text('legacyBackupWarningBody'.tr()),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: Text('cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: () => Get.back(result: true),
          child: Text('legacyBackupWarningConfirm'.tr()),
        ),
      ],
    ),
  );
  return result ?? false;
}

String localizeBackupError(BackupError e) {
  switch (e.kind) {
    case BackupErrorKind.passwordRequired:
      return 'backupPasswordRequired'.tr();
    case BackupErrorKind.wrongPassword:
      return 'backupWrongPassword'.tr();
    case BackupErrorKind.invalidFormat:
      return 'backupInvalidFormat'.tr();
    case BackupErrorKind.io:
      return 'backupIoError'.tr();
  }
}

Future<String?> promptBackupPassword(
  BuildContext context, {
  required String title,
  required String description,
  required bool confirmRequired,
}) async {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  String? errorText;

  final result = await showDialog<String?>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(builder: (ctx, setLocal) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'backupPasswordLabel'.tr(),
                  ),
                ),
                if (confirmRequired) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'backupPasswordConfirmLabel'.tr(),
                    ),
                  ),
                ],
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorText!,
                    style: TextStyle(
                      color: Theme.of(ctx).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () {
                final pw = passwordController.text;
                if (pw.length < 6) {
                  setLocal(() => errorText = 'backupPasswordTooShort'.tr());
                  return;
                }
                if (confirmRequired && pw != confirmController.text) {
                  setLocal(() => errorText = 'backupPasswordMismatch'.tr());
                  return;
                }
                Navigator.pop(dialogContext, pw);
              },
              child: Text('confirm'.tr()),
            ),
          ],
        );
      });
    },
  );

  return result;
}
