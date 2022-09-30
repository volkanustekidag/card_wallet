import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_iban_scanner/flutter_iban_scanner.dart';
import 'package:wallet_app/core/constants/paddings.dart';
import 'package:wallet_app/feature/add_iban_card/bloc/add_iban_card_bloc.dart';

class IbanTextField extends StatelessWidget {
  const IbanTextField({
    Key? key,
    required TextEditingController ibanController,
    required this.focusNode,
    required this.cameras,
  })  : _ibanController = ibanController,
        super(key: key);

  final TextEditingController _ibanController;
  final FocusNode focusNode;
  final List<CameraDescription> cameras;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: PaddingConstants.extraHigh(),
      child: TextField(
        maxLength: 35,
        controller: _ibanController,
        onChanged: (iban) {
          BlocProvider.of<AddIbanCardBloc>(context).add(
            UpdateIbanCardEvent(iban, "iban"),
          );
        },
        style: const TextStyle(color: Colors.white),
        focusNode: focusNode,
        decoration: InputDecoration(
          helperStyle: TextStyle(color: Colors.white),
          prefixIcon: const Icon(
            Icons.numbers,
            color: Colors.white,
          ),
          labelText: "IBAN",
          labelStyle: const TextStyle(color: Colors.white),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
          hintText: '',
          suffixIcon: IconButton(
            icon: Icon(
              Icons.camera_alt,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () => {
              focusNode.unfocus(),
              focusNode.canRequestFocus = false,
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IBANScannerView(
                      cameras: cameras,
                      onScannerResult: (iban) {
                        Navigator.pop(context);
                        BlocProvider.of<AddIbanCardBloc>(context).add(
                          UpdateIbanCardEvent(iban, "iban"),
                        );
                      }),
                ),
              ),
              Future.delayed(
                const Duration(milliseconds: 100),
                () {
                  focusNode.canRequestFocus = true;
                },
              ),
            },
          ),
        ),
      ),
    );
  }
}
