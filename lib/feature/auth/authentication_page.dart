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
  final TextEditingController _textEditingController = TextEditingController();
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
    _textEditingController.clear();
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

        // Clear text field if authentication failed
        if (_authController.authenticationFailed.value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _textEditingController.clear();
            _authController.resetAuthenticationState();
          });
        }

        // Show registration screen if no password exists
        if (_authController.isRegistering.value) {
          return AuthViews(
            textEditingController: _textEditingController,
            text: "createPin",
            onCompleted: _handlePinCompleted,
          );
        }

        // Show login screen (default state)
        return AuthViews(
          textEditingController: _textEditingController,
          text: "enterPin",
          onCompleted: _handlePinCompleted,
        );
      }),
    );
  }
}
