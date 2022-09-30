import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wallet_app/core/constants/app_images.dart';
import 'package:sizer/sizer.dart';
import 'package:wallet_app/core/constants/colors.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();

    Future.delayed(
        const Duration(
          milliseconds: 2000,
        ), () {
      Navigator.pushReplacementNamed(context, "auth");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.primaryColor,
      body: Stack(
        children: [
          Image.asset(AppImages().splashBackground, fit: BoxFit.fill),
          Center(
            child: SvgPicture.asset(AppImages().splashLogo, width: 30.w),
          ),
        ],
      ),
    );
  }
}
