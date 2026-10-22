import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/data/local_services/auth_services/biometric_service.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/services/app_lock_service.dart';
import 'package:wallet_app/ui/components/cw_misc.dart';

Future<void> showAutoLockBottomSheet(BuildContext context) async {
  final lock = Get.find<AppLockService>();
  final picked = await showCwChoiceSheet<int>(
    context,
    title: 'autoLock'.tr(),
    subtitle: 'autoLockSubtitle'.tr(),
    selected: lock.autoLockSeconds.value,
    options: [
      for (final s in AutoLockTime.options) CwChoice(s, AutoLockTime.label(s)),
    ],
  );
  if (picked == null) return;
  try {
    await BiometricService().setAutoLockSeconds(picked);
    lock.autoLockSeconds.value = picked;
  } catch (_) {
    Get.context?.showErrorSnackBar('autoLockTimeUpdateError');
  }
}
