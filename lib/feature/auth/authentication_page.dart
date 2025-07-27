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

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _handlePinCompleted(String password) {
    if (_authController.isRegistering.value) {
      _authController.register(password);
    } else {
      _authController.login(password);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: Obx(() {
        // Show loading spinner when processing
        if (_authController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        }

        // Reset authentication state if failed
        if (_authController.authenticationFailed.value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _authController.resetAuthenticationState();
          });
        }

        // Show registration screen if no password exists
        if (_authController.isRegistering.value) {
          return AuthViews(
            textEditingController: TextEditingController(),
            text: "createPin",
            onCompleted: _handlePinCompleted,
          );
        }

        // Show login screen (default state)
        return AuthViews(
          textEditingController: TextEditingController(),
          text: "enterPin",
          onCompleted: _handlePinCompleted,
        );
      }),
    );
  }
}
