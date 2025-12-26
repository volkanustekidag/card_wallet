import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:wallet_app/core/constants/paddings.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/widgets/add_iban_card_widget.dart';
import 'package:wallet_app/feature/add_iban_card/controller/add_iban_card_controller.dart';
import 'package:wallet_app/feature/add_iban_card/widgets/add_iban_app_bar.dart';
import 'package:wallet_app/feature/add_iban_card/widgets/iban_text_forms.dart';

class AddIbanCardPage extends StatefulWidget {
  final IbanCard? ibanCard; // Opsiyonel parametresi

  const AddIbanCardPage({Key? key, this.ibanCard}) : super(key: key);

  @override
  State<AddIbanCardPage> createState() => _AddIbanCardPageState();
}

class _AddIbanCardPageState extends State<AddIbanCardPage> {
  late TextEditingController _ibanController;
  late FocusNode _ibanFocusNode;
  late final AddIbanCardController _controller =
      Get.find<AddIbanCardController>();
  List<CameraDescription> cameras = [];

  @override
  void initState() {
    super.initState();
    _initCameras();
    _ibanController = TextEditingController();
    _ibanFocusNode = FocusNode();

    if (widget.ibanCard != null) {
      _controller.initializeForEdit(widget.ibanCard!);
    } else {
      _controller.initializeForCreate();
    }
  }

  @override
  void dispose() {
    _ibanController.dispose();
    _ibanFocusNode.dispose();
    super.dispose();
  }

  void _initCameras() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      final availableCams = await availableCameras();
      if (mounted) {
        setState(() {
          cameras = availableCams;
        });
      }
      print('✅ Loaded ${cameras.length} cameras');
    } catch (e) {
      print('❌ Camera initialization error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AddIbanAppBar(ibanCard: widget.ibanCard),
      body: Padding(
        padding: const PaddingConstants.extraHigh(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Obx(() =>
                  AddIbanCardWidget(ibanCard: _controller.currentCard.value)),
            ),
            const SizedBox(height: 24),
            IbanTextFieldForms(
              ibanController: _ibanController,
              focusNode: _ibanFocusNode,
              cameras: cameras,
            ),
          ],
        ),
      ),
    );
  }
}
