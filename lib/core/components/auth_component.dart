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

  const AuthViews({
    Key? key,
    required this.text,
    required this.textEditingController,
    required this.onCompleted,
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
        if (!failed) return;
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
                  return Column(
                    children: [
                      PinCodeTextField(
                        backgroundColor: Colors.transparent,
                        appContext: context,
                        length: 4,
                        controller: widget.textEditingController,
                        obscureText: true,
                        obscuringCharacter: '●',
                        animationType: AnimationType.fade,
                        cursorColor: color.primary,
                        keyboardType: TextInputType.number,
                        autoFocus: !locked,
                        enabled: !locked,
                        cursorHeight: 16,
                        errorAnimationController: _errorAnimationController,
                        textStyle: TextStyle(
                          fontSize: 18,
                          color: color.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(12),
                          fieldHeight: 50,
                          fieldWidth: 50,
                          activeColor: color.primary,
                          inactiveColor: color.outline.withOpacity(0.5),
                          selectedColor: color.secondary,
                          activeFillColor: Colors.transparent,
                          inactiveFillColor: Colors.transparent,
                          selectedFillColor: Colors.transparent,
                          borderWidth: 1.5,
                        ),
                        enableActiveFill: false,
                        onChanged: (_) {},
                        onCompleted: locked ? null : widget.onCompleted,
                      ),
                      if (locked) ...[
                        const SizedBox(height: 12),
                        Text(
                          'pinLockedMessage'.tr(args: [
                            _formatRemaining(authController.pinLockRemaining),
                          ]),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),

              if (widget.text == "enterPin") ...[
                const SizedBox(height: 28),
                GetX<AuthController>(
                  builder: (authController) {
                    if (!authController.showBiometricButton.value) {
                      return const SizedBox.shrink();
                    }
                    return _buildBiometricButton(theme, color, authController);
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBiometricButton(
    ThemeData theme,
    ColorScheme color,
    AuthController authController,
  ) {
    return Column(
      children: [
        Text(
          "or".tr(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(40),
            onTap: () => authController.authenticateWithBiometric(),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.primary,
                    color.primary.withValues(alpha: 0.85),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.primary.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                _getBiometricIcon(authController.availableBiometrics),
                size: 36,
                color: color.onPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          authController.getBiometricDisplayName(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: color.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  IconData _getBiometricIcon(List biometrics) {
    if (biometrics.any((b) => b.toString().contains('face'))) {
      return Icons.face;
    } else if (biometrics.any((b) => b.toString().contains('fingerprint'))) {
      return Icons.fingerprint;
    }
    return Icons.security;
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
