import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/core/controllers/home_controller.dart';
import 'package:wallet_app/core/widgets/loading_widget.dart';
import 'package:wallet_app/feature/home/widgets/home_app_bar.dart';
import 'package:wallet_app/feature/home/widgets/body.dart';
import 'package:wallet_app/feature/home/widgets/speed_dial_floating.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController _homeController;

  @override
  void initState() {
    super.initState();
    _homeController = Get.find<HomeController>();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: ColorConstants.primaryColor,
        floatingActionButton: const SpeedDialFloating(),
        appBar: const HomeAppBar(),
        body: Obx(() {
          if (_homeController.isLoading.value) {
            return const LoadingWidget();
          }
          return HomeBody(controller: _homeController);
        }),
      ),
    );
  }
}
