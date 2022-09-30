import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/core/constants/paddings.dart';
import 'package:wallet_app/core/widgets/iban_cards.dart';
import 'package:wallet_app/feature/add_iban_card/bloc/add_iban_card_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:wallet_app/feature/add_iban_card/widgets/app_bar.dart';
import 'package:wallet_app/feature/add_iban_card/widgets/iban_text_filed_forms.dart';

class AddIbanCard extends StatefulWidget {
  const AddIbanCard({Key? key}) : super(key: key);

  @override
  State<AddIbanCard> createState() => _AddIbanCardState();
}

class _AddIbanCardState extends State<AddIbanCard> {
  late TextEditingController _ibanController;
  List<CameraDescription> cameras = [];

  @override
  void initState() {
    super.initState();
    _initCameras();
    _ibanController = TextEditingController();
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
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    FocusNode focusNode = FocusNode();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: ColorConstants.primaryColor,
      appBar: AddIbanAppBar(),
      body: Padding(
        padding: PaddingConstants.extraHigh(),
        child: Center(
          child: Column(
            children: [
              BlocConsumer<AddIbanCardBloc, AddIbanCardState>(
                listener: (context, state) {
                  if (state is UpdateIbanCardState) {
                    BlocProvider.of<AddIbanCardBloc>(context).add(
                      SaveIbanCardEvent(state.ibanCard),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is SaveIbanCardState) {
                    return IbanCards(ibanCard: state.ibanCard);
                  }

                  return Container();
                },
              ),
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
