import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:wallet_app/core/components/auth_component.dart';
import 'package:wallet_app/core/controllers/change_pin_controller.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/feature/change_pin/widgets/app_bar.dart';

/// Three-stage PIN rotation:
///   1. Verify current PIN (controller-side rate-limited).
///   2. Pick a new PIN — captured locally, not yet persisted.
///   3. Re-enter to confirm. Mismatch → snackbar + restart from stage 2.
///   Match → [ChangePinController.saveNewPin].
///
/// Local-state confirm step (instead of a controller flag) keeps the
/// controller focused on auth I/O; the captured PIN never leaves this
/// widget's memory.
class ChangePinPage extends StatefulWidget {
  const ChangePinPage({super.key});

  @override
  State<ChangePinPage> createState() => _ChangePinPageState();
}

class _ChangePinPageState extends State<ChangePinPage> {
  final TextEditingController _textEditingController = TextEditingController();

  /// Holds the first new-PIN entry between stage 2 and stage 3. Null
  /// means we're still on stage 2 (or before).
  String? _firstNewPin;

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChangePinController>();

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: const ChangePinAppBar(),
      body: Obx(() {
        // Stage 1: verify current PIN.
        if (!controller.currentPinVerified.value) {
          if (controller.verificationFailed.value) {
            _textEditingController.clear();
          }
          return AuthViews(
            key: const ValueKey('change-pin-current'),
            textEditingController: _textEditingController,
            text: 'enterPin',
            onCompleted: (pin) {
              controller.verifyCurrentPin(pin);
              _textEditingController.clear();
            },
          );
        }

        // Stage 2: pick a new PIN.
        if (_firstNewPin == null) {
          return AuthViews(
            key: const ValueKey('change-pin-new'),
            textEditingController: _textEditingController,
            text: 'addNPIN',
            onCompleted: (pin) {
              HapticFeedback.lightImpact();
              setState(() => _firstNewPin = pin);
              _textEditingController.clear();
            },
          );
        }

        // Stage 3: confirm the new PIN.
        return AuthViews(
          key: const ValueKey('change-pin-confirm'),
          textEditingController: _textEditingController,
          text: 'confirmPin',
          onCompleted: (pin) {
            if (pin != _firstNewPin) {
              HapticFeedback.heavyImpact();
              Get.context?.showErrorSnackBar('pinMismatch');
              setState(() => _firstNewPin = null);
              _textEditingController.clear();
              return;
            }
            controller.saveNewPin(pin);
          },
        );
      }),
    );
  }
}
