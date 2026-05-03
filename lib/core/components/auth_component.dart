import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:wallet_app/core/controllers/auth_controller.dart';
import 'package:wallet_app/core/widgets/background_shapes_painter.dart';

class AuthViews extends StatefulWidget {
  final String text;
  final void Function(String)? onCompleted;
  final TextEditingController textEditingController;
  final bool autoFocus;

  const AuthViews({
    Key? key,
    required this.text,
    required this.textEditingController,
    required this.onCompleted,
    this.autoFocus = true,
  }) : super(key: key);

  @override
  State<AuthViews> createState() => _AuthViewsState();
}

class _AuthViewsState extends State<AuthViews> {
  final StreamController<ErrorAnimationType> _errorAnimationController =
      StreamController<ErrorAnimationType>.broadcast();
  Worker? _failureWorker;

  @override
  void initState() {
    super.initState();
    final authController =
        Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
    if (authController != null) {
      _failureWorker =
          ever<bool>(authController.authenticationFailed, (failed) {
        if (!failed || !mounted) return;
        _errorAnimationController.add(ErrorAnimationType.shake);
        HapticFeedback.heavyImpact();
        widget.textEditingController.clear();
      });
    }
  }

  @override
  void dispose() {
    _failureWorker?.dispose();
    _errorAnimationController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: BackgroundShapesPainter()),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.08,
            vertical: size.height * 0.06,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 48, color: color.primary),
              const SizedBox(height: 24),
              Text(
                widget.text.tr(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: color.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              GetX<AuthController>(
                builder: (authController) {
                  final locked = authController.isPinLocked;
                  final hasError = authController.authenticationFailed.value;
                  final busy = authController.isLoading.value;
                  final fieldsEnabled = !locked && !busy;

                  final activeColor =
                      hasError ? color.error : color.primary;
                  final inactiveColor = hasError
                      ? color.error.withValues(alpha: 0.7)
                      : color.outline.withValues(alpha: 0.5);
                  final selectedColor =
                      hasError ? color.error : color.secondary;

                  return Column(
                    children: [
                      PinCodeTextField(
                        backgroundColor: Colors.transparent,
                        appContext: context,
                        length: 4,
                        controller: widget.textEditingController,
                        autoDisposeControllers: false,
                        obscureText: true,
                        obscuringCharacter: '●',
                        animationType: AnimationType.fade,
                        cursorColor: activeColor,
                        keyboardType: TextInputType.number,
                        autoFocus: widget.autoFocus && fieldsEnabled,
                        enabled: fieldsEnabled,
                        cursorHeight: 16,
                        errorAnimationController: _errorAnimationController,
                        textStyle: TextStyle(
                          fontSize: 18,
                          color:
                              hasError ? color.error : color.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(12),
                          fieldHeight: 50,
                          fieldWidth: 50,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                          selectedColor: selectedColor,
                          activeFillColor: Colors.transparent,
                          inactiveFillColor: Colors.transparent,
                          selectedFillColor: Colors.transparent,
                          borderWidth: 1.5,
                        ),
                        enableActiveFill: false,
                        onChanged: (_) {},
                        onCompleted:
                            fieldsEnabled ? widget.onCompleted : null,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 24,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: busy
                              ? SizedBox(
                                  key: const ValueKey('pin-loader'),
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      color.primary,
                                    ),
                                  ),
                                )
                              : locked
                                  ? Text(
                                      key: const ValueKey('pin-locked'),
                                      'pinLockedMessage'.tr(args: [
                                        _formatRemaining(
                                            authController.pinLockRemaining),
                                      ]),
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        color: color.error,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )
                                  : const SizedBox.shrink(
                                      key: ValueKey('pin-idle'),
                                    ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatRemaining(Duration d) {
    final secs = d.inSeconds;
    if (secs >= 60) {
      final minutes = (secs / 60).ceil();
      return '$minutes min';
    }
    return '$secs s';
  }
}
