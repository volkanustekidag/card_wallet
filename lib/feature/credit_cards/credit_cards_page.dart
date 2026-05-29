import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wallet_app/feature/credit_cards/controller/credit_card_controller.dart';
import 'package:wallet_app/core/widgets/empty_list_info.dart';
import 'package:wallet_app/core/widgets/loading_widget.dart';
import 'package:wallet_app/feature/credit_cards/widgets/app_bar.dart';
import 'package:wallet_app/feature/credit_cards/widgets/credit_cards_body.dart';

class CreditCardsPage extends StatefulWidget {
  const CreditCardsPage({Key? key}) : super(key: key);

  @override
  State<CreditCardsPage> createState() => _CreditCardsPageState();
}

class _CreditCardsPageState extends State<CreditCardsPage> {
  late final CreditCardController _controller =
      Get.find<CreditCardController>();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CCAppBar(),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const LoadingWidget();
        }
        if (_controller.creditCards.isEmpty) {
          return const EmptyListInfo(
            ctaRoute: '/addCreditCard',
            ctaLabel: 'addFirstCC',
            ctaIcon: Icons.credit_card,
          );
        }
        return Body(controller: _controller);
      }),
    );
  }
}
