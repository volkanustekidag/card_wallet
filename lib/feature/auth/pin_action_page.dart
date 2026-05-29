import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:wallet_app/core/components/auth_component.dart';
import 'package:wallet_app/core/controllers/auth_controller.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';

/// What kind of PIN flow this page should run.
enum PinAction { create, verify }

/// Reusable PIN entry page for one-shot create/verify flows. Pushed via
/// `Get.to<bool>(() => const PinActionPage(), arguments: PinAction.x)` —
/// named-route push (`Get.toNamed<bool>(...)`) crashes with a `GetPageRoute<dynamic>`
/// → `Route<bool?>` cast error in GetX 4.7.x, so always go through the
/// builder form. Returns `true` when the user successfully creates or
/// verifies, `null` if the user backs out without completing.
///
/// - [PinAction.create]: two-step entry. First the user picks a PIN, then
///   re-enters it for confirmation. Mismatch → snackbar + reset to step 1.
///   Match → [AuthController.registerStandalone] (which also flips
///   [AuthController.hasPassword]). The hash + box-write does take a
///   moment on weak devices, so [AuthViews] surfaces a spinner via
///   `authController.isLoading`.
/// - [PinAction.verify]: single entry. Doesn't navigate to /home — just
///   verifies the currently-stored PIN via [AuthController.verifyPin].
///   Used to gate the settings "disable lock" flow. Trips rate-limiting
///   on failure (same policy as the lock screen).
class PinActionPage extends StatefulWidget {
  const PinActionPage({Key? key}) : super(key: key);

  @override
  State<PinActionPage> createState() => _PinActionPageState();
}

class _PinActionPageState extends State<PinActionPage> {
  final TextEditingController _pinController = TextEditingController();
  late final PinAction _action;

  /// Captures the PIN entered in the first step of [PinAction.create]. Stays
  /// null in verify mode and during the create-mode first entry. Holding it
  /// in transient state (no persistence) means a backgrounded sheet that
  /// gets recreated will safely restart the flow.
  String? _firstEntry;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    _action = args is PinAction ? args : PinAction.verify;
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _onCompleted(String pin) async {
    final authController = Get.find<AuthController>();
    if (authController.isLoading.value) return;

    if (_action == PinAction.verify) {
      final ok = await authController.verifyPin(pin);
      if (!mounted) return;
      if (ok) {
        Get.back<bool>(result: true);
      } else {
        // verifyPin already triggered the shake + clear via
        // authenticationFailed; just defensively clear here too in case
        // the worker missed the signal.
        _pinController.clear();
      }
      return;
    }

    // PinAction.create — two-step entry.
    if (_firstEntry == null) {
      // Step 1: capture the pick, swap the prompt to "confirm".
      HapticFeedback.lightImpact();
      setState(() {
        _firstEntry = pin;
      });
      _pinController.clear();
      return;
    }

    // Step 2: must match the first entry.
    if (pin != _firstEntry) {
      HapticFeedback.heavyImpact();
      Get.context?.showErrorSnackBar('pinMismatch');
      // Restart from step 1 — don't keep them on the confirm screen with
      // a mismatch they can't undo.
      setState(() {
        _firstEntry = null;
      });
      _pinController.clear();
      return;
    }

    // Match → register. AuthController flips hasPassword + isLoading on
    // its own; AuthViews shows the spinner during the hash.
    final ok = await authController.registerStandalone(pin);
    if (!mounted) return;
    if (ok) {
      Get.back<bool>(result: true);
    } else {
      // registerStandalone already snackbarred the error.
      setState(() {
        _firstEntry = null;
      });
      _pinController.clear();
    }
  }

  String get _promptKey {
    switch (_action) {
      case PinAction.create:
        return _firstEntry == null ? 'createPin' : 'confirmPin';
      case PinAction.verify:
        return 'enterPin';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Get.back<bool>(result: false),
          ),
        ),
        resizeToAvoidBottomInset: true,
        // Re-key on the prompt so AuthViews resets its internal listeners
        // and animation controllers cleanly between create-step-1 and
        // create-step-2. Without this, the first-entry's stale failure
        // worker would still be wired to the second-entry's pin field.
        body: AuthViews(
          key: ValueKey(_promptKey),
          textEditingController: _pinController,
          text: _promptKey,
          onCompleted: _onCompleted,
        ),
      ),
    );
  }
}
