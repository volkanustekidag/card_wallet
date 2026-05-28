import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/controllers/auth_controller.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/utils/secure_storage_provider.dart';
import 'package:wallet_app/feature/auth/pin_action_page.dart';

/// Persisted across launches so we don't pester users who said "Sonra".
/// They can still enable lock from settings whenever they want.
const String _kPinPromptDismissedKey = 'pin_prompt_dismissed';

/// Soft nudge shown after the user adds their very first card. Three guards
/// keep this from becoming naggy:
///
///   1. PIN is not already set (`hasPassword == false`).
///   2. The user just added their first card overall
///      (`totalCardCountAfterAdd == 1`).
///   3. The user hasn't already tapped "Sonra" in a previous session.
///
/// On accept → opens [PinActionPage] in `create` mode. On dismiss → flips
/// the "dismissed" flag so we never ask again. Reachable any time later
/// from Settings → Uygulamayı Kilitle.
Future<void> maybePromptPinSetup({
  required int totalCardCountAfterAdd,
}) async {
  if (totalCardCountAfterAdd != 1) return;

  if (!Get.isRegistered<AuthController>()) return;
  final auth = Get.find<AuthController>();
  if (auth.hasPassword.value) return;

  const storage = SecureStorageProvider.instance;
  String? dismissed;
  try {
    dismissed = await storage.read(key: _kPinPromptDismissedKey);
  } catch (_) {
    dismissed = null;
  }
  if (dismissed == 'true') {
    // iOS keeps Keychain entries across uninstalls. We've already checked
    // hasPassword above — if we're here, there is no PIN, so a stored
    // `dismissed=true` is almost certainly a stale entry from a previous
    // install lifetime. Clear it and let the prompt fire as if this were
    // a fresh user. (The other reading — same-install user who said
    // "Sonra" before — can't reach this branch because that user already
    // returned at `totalCardCountAfterAdd != 1`: this gate only fires on
    // the very first card.)
    try {
      await storage.delete(key: _kPinPromptDismissedKey);
    } catch (_) {
      // Best-effort; if delete fails the prompt may show again next time
      // — slightly worse UX than ideal, but not a functional bug.
    }
  }

  final context = Get.context;
  if (context == null) return;

  final accepted = await Get.dialog<bool>(
    AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        'pinPromptTitle'.tr(),
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        'pinPromptMessage'.tr(),
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back<bool>(result: false),
          child: Text(
            'pinPromptLater'.tr(),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Get.back<bool>(result: true),
          child: Text(
            'pinPromptYes'.tr(),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
    barrierDismissible: false,
  );

  if (accepted == true) {
    // Direct widget push (Get.to) instead of named route — avoids a race
    // between the dialog dismiss animation and the route push that can
    // silently swallow the navigation when both happen on the same frame.
    await Future<void>.delayed(Duration.zero);
    final created = await Get.to<bool>(
      () => const PinActionPage(),
      arguments: PinAction.create,
    );
    // hasPassword is updated inside the controller; here we just surface
    // the outcome so the user gets feedback without bouncing back to home
    // silently.
    if (created == true) {
      Get.context?.showSuccessSnackBar('pinCreated');
    }
  } else {
    try {
      await storage.write(key: _kPinPromptDismissedKey, value: 'true');
    } catch (_) {
      // Best-effort; if storage fails the worst case is we ask again next
      // first-card. Not a security issue, just a minor UX wobble.
    }
  }
}
