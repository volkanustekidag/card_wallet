import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/data/services/backup_service.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/services/analytics_service.dart';
import 'package:wallet_app/core/services/error_reporter.dart';
import 'package:wallet_app/core/components/dialog/delete_dialog.dart';
import 'package:wallet_app/ui/components/cw_button.dart';
import 'package:wallet_app/ui/components/cw_field.dart';
import 'package:wallet_app/ui/components/cw_misc.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

/// Settings › Restore: confirm, pick the file, ask for its password and
/// replace the wallet. Also started from the home "cards stay on this
/// device" notice. Callers handle the premium gate.
Future<void> restoreFromBackupFlow(BuildContext context) async {
  final confirmed = await showConfirmActionSheet(
    context: context,
    title: 'restoreTitle'.tr(),
    content: 'restoreContent'.tr(),
    confirmText: 'confirm'.tr(),
    cancelText: 'cancel'.tr(),
    destructive: false,
    glyph: CwIcons.restore,
  );
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
  final ctx = Get.context;
  if (ctx == null) return false;
  final result = await showConfirmActionSheet(
    context: ctx,
    title: 'legacyBackupWarningTitle'.tr(),
    content: 'legacyBackupWarningBody'.tr(),
    confirmText: 'legacyBackupWarningConfirm'.tr(),
    cancelText: 'cancel'.tr(),
    destructive: true,
    glyph: CwIcons.warning,
  );
  return result;
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

  final result = await showCwSheet<String>(
    context,
    builder: (sheet) => StatefulBuilder(builder: (ctx, setLocal) {
      final c = CwColors.of(ctx);
      void submit() {
        final pw = passwordController.text;
        if (pw.length < 6) {
          setLocal(() => errorText = 'backupPasswordTooShort'.tr());
          return;
        }
        if (confirmRequired && pw != confirmController.text) {
          setLocal(() => errorText = 'backupPasswordMismatch'.tr());
          return;
        }
        Navigator.pop(sheet, pw);
      }

      return SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title,
                  style: CwType.title.copyWith(color: c.ink, fontSize: 20)),
              const SizedBox(height: 6),
              Text(description,
                  style: CwType.callout.copyWith(color: c.ink2, height: 1.4)),
              const SizedBox(height: 16),
              CwField(
                controller: passwordController,
                label: 'backupPasswordLabel'.tr(),
                obscure: true,
                autofocus: true,
                error: confirmRequired ? null : errorText,
                onSubmitted: (_) => confirmRequired ? null : submit(),
              ),
              if (confirmRequired) ...[
                const SizedBox(height: 10),
                CwField(
                  controller: confirmController,
                  label: 'backupPasswordConfirmLabel'.tr(),
                  obscure: true,
                  error: errorText,
                  onSubmitted: (_) => submit(),
                ),
              ],
              const SizedBox(height: 18),
              CwButton('confirm'.tr(), onPressed: submit),
              const SizedBox(height: 6),
              CwButton.ghost('cancel'.tr(),
                  onPressed: () => Navigator.pop(sheet)),
            ],
          ),
        ),
      );
    }),
  );

  return result;
}
