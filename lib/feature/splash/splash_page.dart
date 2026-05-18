import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wallet_app/core/constants/app_images.dart';
import 'package:wallet_app/core/data/local_services/auth_services/authentication_service.dart';
import 'package:wallet_app/core/router/getx_routes.dart';
import 'package:wallet_app/feature/onboarding/onboarding_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final showOnboarding = await OnboardingPage.shouldShow();
      if (!mounted) return;
      if (showOnboarding) {
        Get.offAllNamed(AppRoutes.onboarding);
        return;
      }
      // PIN is opt-in now: existing users with a PIN keep their lock
      // screen; fresh users go straight to home and may set up a PIN
      // later (via the post-add prompt or settings). hasPasswordSync is
      // safe here — main() opens the auth box before runApp.
      final hasPassword = AuthenticationService().hasPasswordSync();
      Get.offAllNamed(hasPassword ? AppRoutes.auth : AppRoutes.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Image.asset(
            AppImages.logo,
            width: size.width * 0.3,
          ),
        ),
      ),
    );
  }
}
