import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:wallet_app/core/constants/app_images.dart';
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
      Get.offAllNamed(
        showOnboarding ? AppRoutes.onboarding : AppRoutes.auth,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Image.asset(
            AppImages.logo,
            width: 30.w,
          ),
        ),
      ),
    );
  }
}
