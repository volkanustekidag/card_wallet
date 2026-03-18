import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:sizer/sizer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/widgets/background_shapes_painter.dart';
import 'package:wallet_app/core/controllers/auth_controller.dart';

class AuthViews extends StatelessWidget {
  final String text;
  final void Function(String)? onCompleted;
  final TextEditingController _textEditingController;

  const AuthViews({
    Key? key,
    required this.text,
    required TextEditingController textEditingController,
    required this.onCompleted,
  })  : _textEditingController = textEditingController,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Stack(
      children: [
        // Background Shapes
        Positioned.fill(
          child: CustomPaint(
            painter: BackgroundShapesPainter(),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 42.sp, color: color.primary),
              const SizedBox(height: 24),
              Text(
                text.tr(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: color.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              PinCodeTextField(
                backgroundColor: Colors.transparent,
                appContext: context,
                length: 4,
                controller: _textEditingController,
                obscureText: true,
                obscuringCharacter: '●',
                animationType: AnimationType.fade,
                cursorColor: color.primary,
                keyboardType: TextInputType.number,
                autoFocus: true,
                cursorHeight: 16,
                textStyle: TextStyle(
                  fontSize: 16.sp,
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
                onCompleted: onCompleted,
              ),

              // Biometric Button (only show for login, not registration)
              if (text == "enterPin") ...[
                const SizedBox(height: 32),
                GetX<AuthController>(
                  builder: (authController) {
                    if (!authController.showBiometricButton.value) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      children: [
                        Text(
                          "or".tr(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: color.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: color.primary.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () {
                              authController.authenticateWithBiometric();
                            },
                            icon: Icon(
                              _getBiometricIcon(
                                  authController.availableBiometrics),
                              size: 32,
                              color: color.primary,
                            ),
                            iconSize: 32,
                            padding: const EdgeInsets.all(16),
                            constraints: const BoxConstraints(
                              minWidth: 64,
                              minHeight: 64,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          authController.getBiometricDisplayName(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: color.onSurface.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  IconData _getBiometricIcon(List biometrics) {
    // Check for specific biometric types and return appropriate icon
    if (biometrics.any((b) => b.toString().contains('face'))) {
      return Icons.face;
    } else if (biometrics.any((b) => b.toString().contains('fingerprint'))) {
      return Icons.fingerprint;
    } else {
      return Icons.security; // Default security icon
    }
  }
}
