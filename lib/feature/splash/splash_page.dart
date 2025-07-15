import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:wallet_app/core/constants/app_images.dart';
import 'package:sizer/sizer.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/core/router/getx_routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToAuth();
  }

  _navigateToAuth() {
    Future.delayed(
      const Duration(milliseconds: 2000),
      () {
        Get.offAllNamed(AppRoutes.auth);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.primaryColor,
      body: Stack(
        children: [
          Image.asset(
            AppImages().splashBackground,
            fit: BoxFit.fill,
            width: double.infinity,
            height: double.infinity,
          ),
          Center(
            child: SvgPicture.asset(
              AppImages().splashLogo,
              width: 30.w,
            ),
          ),
        ],
      ),
    );
  }
}
