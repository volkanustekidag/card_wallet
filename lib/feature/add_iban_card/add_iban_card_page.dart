import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/core/constants/paddings.dart';
import 'package:wallet_app/core/controllers/add_iban_card_controller.dart';
import 'package:wallet_app/core/widgets/iban_cards.dart';
import 'package:wallet_app/feature/add_iban_card/widgets/add_iban_app_bar.dart';
import 'package:wallet_app/feature/add_iban_card/widgets/iban_text_forms.dart';

class AddIbanCardPage extends StatefulWidget {
  const AddIbanCardPage({Key? key}) : super(key: key);

  @override
  State<AddIbanCardPage> createState() => _AddIbanCardPageState();
}

class _AddIbanCardPageState extends State<AddIbanCardPage> {
  late TextEditingController _ibanController;
  late final AddIbanCardController _controller;
  List<CameraDescription> cameras = [];

  @override
  void initState() {
    super.initState();
    _initCameras();
    _ibanController = TextEditingController();
    _controller = Get.find<AddIbanCardController>();
  }

  @override
  void dispose() {
    _ibanController.dispose();
    super.dispose();
  }

  void _initCameras() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      cameras = await availableCameras();
    } catch (e) {
      // Handle camera initialization error
    }
  }

  @override
  Widget build(BuildContext context) {
    FocusNode focusNode = FocusNode();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: ColorConstants.primaryColor,
      appBar: const AddIbanAppBar(),
      body: Padding(
        padding: const PaddingConstants.extraHigh(),
        child: Center(
          child: Column(
            children: [
              Obx(() => IbanCards(ibanCard: _controller.currentCard.value)),
              IbanTextFieldForms(
                  ibanController: _ibanController,
                  focusNode: focusNode,
                  cameras: cameras)
            ],
          ),
        ),
      ),
    );
  }
}
