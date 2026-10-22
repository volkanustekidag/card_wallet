import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/controllers/auth_controller.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

/// PIN entry used by the lock screen, PIN creation/verification and PIN
/// change: night stage, four dots and an in-app keypad (no system keyboard
/// popping up under a Face ID prompt). Wrong PINs shake the dots.
class AuthViews extends StatefulWidget {
  /// Translation key for the title (`enterPin`, `createPin`, `confirmPin`…).
  final String text;
  final void Function(String)? onCompleted;
  final TextEditingController textEditingController;

  /// Kept for API compatibility; the keypad is always on screen.
  final bool autoFocus;

  /// Shows the biometric key (lock screen only).
  final VoidCallback? onBiometric;

  /// Shows "Forgot?" while no digit is typed.
  final VoidCallback? onForgot;

  /// The app lock screen: "Card Wallet is locked" headline.
  final bool lockScreen;

  const AuthViews({
    Key? key,
    required this.text,
    required this.textEditingController,
    required this.onCompleted,
    this.autoFocus = true,
    this.onBiometric,
    this.onForgot,
    this.lockScreen = false,
  }) : super(key: key);

  @override
  State<AuthViews> createState() => _AuthViewsState();
}

class _AuthViewsState extends State<AuthViews>
    with SingleTickerProviderStateMixin {
  static const _length = 4;
  Worker? _failureWorker;
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  String get _pin => widget.textEditingController.text;

  @override
  void initState() {
    super.initState();
    widget.textEditingController.addListener(_onText);
    final auth =
        Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
    if (auth != null) {
      _failureWorker = ever<bool>(auth.authenticationFailed, (failed) {
        if (!failed || !mounted) return;
        HapticFeedback.heavyImpact();
        _shake.forward(from: 0);
        widget.textEditingController.clear();
      });
    }
  }

  void _onText() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.textEditingController.removeListener(_onText);
    _failureWorker?.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _tap(String d, bool enabled) {
    if (!enabled || _pin.length >= _length) return;
    HapticFeedback.selectionClick();
    final next = _pin + d;
    widget.textEditingController.text = next;
    if (next.length == _length) widget.onCompleted?.call(next);
  }

  void _back() {
    if (_pin.isEmpty) return;
    HapticFeedback.selectionClick();
    widget.textEditingController.text = _pin.substring(0, _pin.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    const night = CwColors.night;
    final isLock = widget.lockScreen;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: night.bg,
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.55),
                    radius: 0.9,
                    colors: [Color(0xFF1E1E5A), Color(0x000B0C0F)],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: GetX<AuthController>(
                builder: (auth) {
                  final locked = auth.isPinLocked;
                  final busy = auth.isLoading.value;
                  final error = auth.authenticationFailed.value;
                  final enabled = !locked && !busy;
                  return Column(
                    children: [
                      const Spacer(flex: 3),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: CwIcon(
                          isLock ? CwIcons.lock : CwIcons.shield,
                          size: 28,
                          color: night.ink,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          isLock ? 'cwLocked'.tr() : widget.text.tr(),
                          textAlign: TextAlign.center,
                          style: CwType.title.copyWith(color: night.ink),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 36,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            locked
                                ? 'pinLockedMessage'.tr(args: [
                                    AuthController.formatLockRemaining(
                                        auth.pinLockRemaining),
                                  ])
                                : isLock
                                    ? 'enterPin'.tr()
                                    : '',
                            textAlign: TextAlign.center,
                            style: CwType.footnote.copyWith(
                                color: locked ? night.danger : night.mute),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      AnimatedBuilder(
                        animation: _shake,
                        builder: (_, child) => Transform.translate(
                          offset: Offset(
                              math.sin(_shake.value * math.pi * 6) *
                                  10 *
                                  (1 - _shake.value),
                              0),
                          child: child,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < _length; i++)
                              AnimatedContainer(
                                duration: CwMotion.fast,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 9),
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i < _pin.length
                                      ? (error ? night.danger : night.ink)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: error
                                        ? night.danger
                                        : night.ink.withValues(alpha: 0.6),
                                    width: 1.6,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 40,
                        child: busy
                            ? const Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                ),
                              )
                            : null,
                      ),
                      const Spacer(flex: 2),
                      _Keypad(
                        enabled: enabled,
                        onDigit: (d) => _tap(d, enabled),
                        onBack: _back,
                        showBack: _pin.isNotEmpty,
                        onBiometric: widget.onBiometric,
                        onForgot: widget.onForgot,
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onBack;
  final bool showBack;
  final VoidCallback? onBiometric;
  final VoidCallback? onForgot;

  const _Keypad({
    required this.enabled,
    required this.onDigit,
    required this.onBack,
    required this.showBack,
    this.onBiometric,
    this.onForgot,
  });

  @override
  Widget build(BuildContext context) {
    const night = CwColors.night;
    Widget key(String d) => _Key(
          onTap: enabled ? () => onDigit(d) : null,
          child: Text(d,
              style: CwType.display.copyWith(
                  color: night.ink, fontSize: 30, fontWeight: FontWeight.w400)),
        );
    Widget row(List<Widget> keys) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: keys,
        );
    final left = onBiometric != null
        ? _Key(
            plain: true,
            semantic: 'biometricAuthReason'.tr(),
            onTap: enabled ? onBiometric : null,
            child: const CwIcon(CwIcons.faceId, size: 30, color: Colors.white),
          )
        : const SizedBox(width: _Key.size, height: _Key.size);
    final right = showBack
        ? _Key(
            plain: true,
            semantic: MaterialLocalizations.of(context).deleteButtonTooltip,
            onTap: onBack,
            child: const CwIcon(CwIcons.backspace, size: 26, color: Colors.white),
          )
        : onForgot != null
            ? _Key(
                plain: true,
                onTap: onForgot,
                child: Text('cwForgot'.tr(),
                    style: CwType.callout.copyWith(color: night.ink2)),
              )
            : const SizedBox(width: _Key.size, height: _Key.size);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        children: [
          row([key('1'), key('2'), key('3')]),
          const SizedBox(height: 14),
          row([key('4'), key('5'), key('6')]),
          const SizedBox(height: 14),
          row([key('7'), key('8'), key('9')]),
          const SizedBox(height: 14),
          row([left, key('0'), right]),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  static const double size = 76;
  final Widget child;
  final VoidCallback? onTap;
  final bool plain;
  final String? semantic;

  const _Key({
    required this.child,
    required this.onTap,
    this.plain = false,
    this.semantic,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: semantic,
        child: Material(
          color: plain ? Colors.transparent : Colors.white.withValues(alpha: 0.07),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Center(child: child),
            ),
          ),
        ),
      );
}
