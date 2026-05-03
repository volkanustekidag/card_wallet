import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wallet_app/core/controllers/auth_controller.dart';
import 'package:wallet_app/core/components/auth_component.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({Key? key}) : super(key: key);

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  late final AuthController _authController;
  final TextEditingController _pinController = TextEditingController();
  Worker? _autoBiometricWorker;
  bool _autoBiometricFired = false;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();

    // Biometric init runs async in the controller. Try once after the first
    // frame in case it already resolved, and again whenever the eligibility
    // flag flips — whichever lands first wins, the flag guards re-entry.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeAutoTriggerBiometric();
    });
    _autoBiometricWorker =
        ever<bool>(_authController.showBiometricButton, (_) {
      _maybeAutoTriggerBiometric();
    });
  }

  void _maybeAutoTriggerBiometric() {
    if (!mounted || _autoBiometricFired) return;
    if (_authController.isRegistering.value) return;
    if (!_authController.showBiometricButton.value) return;
    if (_authController.isLoading.value) return;
    if (_authController.isPinLocked) return;
    _autoBiometricFired = true;
    _authController.authenticateWithBiometric();
  }

  @override
  void dispose() {
    _autoBiometricWorker?.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _handlePinCompleted(String password) {
    if (_authController.isLoading.value) return;
    if (_authController.isRegistering.value) {
      _authController.register(password);
    } else {
      _authController.login(password);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        resizeToAvoidBottomInset: true,
        body: Obx(() {
          final isRegistering = _authController.isRegistering.value;
          // Wait for the async biometric probe to resolve before mounting
          // AuthViews on the login flow. Otherwise the PIN field auto-focuses
          // for a frame, the keyboard pops up, and only then the biometric
          // prompt slides in over it. Registration has no biometric step so
          // it can render immediately.
          if (!isRegistering && !_authController.biometricInitDone.value) {
            return const SizedBox.shrink();
          }
          // Suppress keyboard auto-focus on the login flow when biometric is
          // set up — the system biometric prompt is about to take over the
          // screen and we don't want the keyboard sliding up underneath it.
          final autoFocus =
              isRegistering || !_authController.showBiometricButton.value;
          return AuthViews(
            key: ValueKey(isRegistering ? 'register' : 'login'),
            textEditingController: _pinController,
            text: isRegistering ? "createPin" : "enterPin",
            autoFocus: autoFocus,
            onCompleted: _handlePinCompleted,
          );
        }),
      ),
    );
  }
}
