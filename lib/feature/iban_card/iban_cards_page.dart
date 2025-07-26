import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wallet_app/core/controllers/iban_card_controller.dart';
import 'package:wallet_app/core/widgets/loading_widget.dart';
import 'package:wallet_app/feature/iban_card/widgets/app_bar.dart';
import 'package:wallet_app/feature/iban_card/widgets/iban_cards_body.dart';

class IbanCardsPage extends StatefulWidget {
  const IbanCardsPage({Key? key}) : super(key: key);

  @override
  State<IbanCardsPage> createState() => _IbanCardsPageState();
}

class _IbanCardsPageState extends State<IbanCardsPage> {
  late final IbanCardController _controller = Get.put(IbanCardController());

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: const IbanCardsAppBar(),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const LoadingWidget();
        }
        return IbanCardsBody(controller: _controller);
      }),
    );
  }
}
