import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/data/local_services/auth_services/biometric_service.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/services/app_lock_service.dart';

Future<void> showAutoLockBottomSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _AutoLockBottomSheetBody(),
  );
}

class _AutoLockBottomSheetBody extends StatelessWidget {
  const _AutoLockBottomSheetBody();

  Future<void> _select(BuildContext context, int seconds) async {
    final lock = Get.find<AppLockService>();
    try {
      await BiometricService().setAutoLockSeconds(seconds);
      lock.autoLockSeconds.value = seconds;
    } catch (_) {
      Get.context?.showErrorSnackBar('autoLockTimeUpdateError');
    }
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final lock = Get.find<AppLockService>();
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                'autoLock'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'autoLockSubtitle'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Obx(() {
              final selected = lock.autoLockSeconds.value;
              return Column(
                children: [
                  for (final seconds in AutoLockTime.options)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      title: Text(
                        AutoLockTime.label(seconds),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      trailing: seconds == selected
                          ? Icon(Icons.check_circle, color: colorScheme.primary)
                          : Icon(
                              Icons.radio_button_unchecked,
                              color: colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                      onTap: () => _select(context, seconds),
                    ),
                ],
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
