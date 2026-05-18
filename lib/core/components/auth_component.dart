import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:wallet_app/core/controllers/auth_controller.dart';

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

class _AuthViewsState extends State<AuthViews>
    with SingleTickerProviderStateMixin {
  final StreamController<ErrorAnimationType> _errorAnimationController =
      StreamController<ErrorAnimationType>.broadcast();
  Worker? _failureWorker;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

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
    _pulseController.dispose();
    super.dispose();
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'confirmPin':
        return Icons.verified_user_rounded;
      case 'createPin':
      case 'addNPIN':
        return Icons.lock_outline_rounded;
      case 'enterPin':
      default:
        return Icons.lock_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = color.primary;

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.7),
                radius: 1.1,
                colors: [
                  accent.withValues(alpha: isDark ? 0.32 : 0.20),
                  accent.withValues(alpha: isDark ? 0.10 : 0.06),
                  Colors.transparent,
                ],
                stops: const [0, 0.55, 1],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 24,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _GlowIcon(
                  icon: _iconFor(widget.text),
                  accent: accent,
                  pulse: _pulseController,
                ),
                const SizedBox(height: 28),
                Text(
                  widget.text.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 32),
                GetX<AuthController>(
                  builder: (authController) {
                    final locked = authController.isPinLocked;
                    final hasError = authController.authenticationFailed.value;
                    final busy = authController.isLoading.value;
                    final fieldsEnabled = !locked && !busy;

                    final activeColor = hasError ? color.error : accent;
                    final inactiveColor = hasError
                        ? color.error.withValues(alpha: 0.7)
                        : color.outline.withValues(alpha: 0.45);
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
                          cursorHeight: 18,
                          errorAnimationController: _errorAnimationController,
                          textStyle: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            color: hasError ? color.error : color.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(14),
                            fieldHeight: 56,
                            fieldWidth: 56,
                            activeColor: activeColor,
                            inactiveColor: inactiveColor,
                            selectedColor: selectedColor,
                            activeFillColor: accent.withValues(alpha: 0.06),
                            inactiveFillColor: Colors.transparent,
                            selectedFillColor: accent.withValues(alpha: 0.10),
                            borderWidth: 1.4,
                          ),
                          enableActiveFill: true,
                          onChanged: (_) {},
                          onCompleted:
                              fieldsEnabled ? widget.onCompleted : null,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 24,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: busy
                                ? SizedBox(
                                    key: const ValueKey('pin-loader'),
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(accent),
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
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ).copyWith(color: color.error),
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

/// Lock icon inside a soft radial-glow disc with a slow pulsing ring —
/// matches the onboarding feature-icon treatment so the lock screen reads
/// as part of the same visual family.
class _GlowIcon extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final AnimationController pulse;
  const _GlowIcon({
    required this.icon,
    required this.accent,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) {
        final t = pulse.value;
        final ringScale = 1.0 + 0.10 * math.sin(t * math.pi);
        final ringAlpha = 0.16 + 0.10 * (1 - (t - 0.5).abs() * 2);
        return SizedBox(
          width: 108,
          height: 108,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: ringScale,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accent.withValues(alpha: ringAlpha),
                      width: 1.4,
                    ),
                  ),
                ),
              ),
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accent.withValues(alpha: 0.22),
                      accent.withValues(alpha: 0.06),
                    ],
                  ),
                ),
                child: Icon(icon, size: 40, color: accent),
              ),
            ],
          ),
        );
      },
    );
  }
}
