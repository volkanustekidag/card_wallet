import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wallet_app/core/controllers/credit_card_controller.dart';
import 'package:wallet_app/core/widgets/loading_widget.dart';
import 'package:wallet_app/core/widgets/banner_ad_widget.dart';
import 'package:wallet_app/feature/credit_cards/widgets/app_bar.dart';
import 'package:wallet_app/feature/credit_cards/widgets/credit_cards_body.dart';

class CreditCardsPage extends StatefulWidget {
  const CreditCardsPage({Key? key}) : super(key: key);

  @override
  State<CreditCardsPage> createState() => _CreditCardsPageState();
}

class _CreditCardsPageState extends State<CreditCardsPage> {
  late final CreditCardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<CreditCardController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: const CCAppBar(),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const LoadingWidget();
        }
        return Column(
          children: [
            Expanded(
              child: Body(controller: _controller),
            ),
            const BannerAdWidget(),
          ],
        );
      }),
    );
  }
}
