import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wallet_app/feature/iban_card/controller/iban_card_controller.dart';
import 'package:wallet_app/core/widgets/empty_list_info.dart';
import 'package:wallet_app/core/widgets/loading_widget.dart';
import 'package:wallet_app/feature/iban_card/widgets/app_bar.dart';
import 'package:wallet_app/feature/iban_card/widgets/iban_cards_body.dart';

class IbanCardsPage extends StatefulWidget {
  const IbanCardsPage({Key? key}) : super(key: key);

  @override
  State<IbanCardsPage> createState() => _IbanCardsPageState();
}

class _IbanCardsPageState extends State<IbanCardsPage> {
  late final IbanCardController _controller = Get.find<IbanCardController>();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const IbanCardsAppBar(),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const LoadingWidget();
        }
        if (_controller.ibanCards.isEmpty) {
          return const EmptyListInfo(
            ctaRoute: '/addIbanCard',
            ctaLabel: 'addFirstIC',
            ctaIcon: Icons.account_balance,
          );
        }
        return IbanCardsBody(controller: _controller);
      }),
    );
  }
}
