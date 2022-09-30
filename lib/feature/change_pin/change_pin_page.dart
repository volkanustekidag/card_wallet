import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/components/auth_component.dart';
import 'package:wallet_app/feature/change_pin/bloc/change_pin_bloc.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/feature/change_pin/widgets/app_bar.dart';

class ChangePinPage extends StatelessWidget {
  ChangePinPage({super.key});

  final TextEditingController _textEditingController = TextEditingController();

  bool checkListenerState(CompletedState state) => state is CompletedState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061720),
      appBar: ChangePinAppBar(),
      body: BlocConsumer<ChangePinBloc, ChangePinState>(
        listener: (context, state) {
          if (state is CompletedState) {
            context.showSnackBarInfo(context, Colors.green, "succChan");

            BlocProvider.of<ChangePinBloc>(context).emit(
              ChangePinInitial(),
            );

            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          if (state is ChangePinInitial || state is FaiulerState) {
            _textEditingController.clear();

            return AuthViews(
              textEditingController: _textEditingController,
              text: "enterPin",
              onCompleted: (pin) {
                BlocProvider.of<ChangePinBloc>(context).add(
                  CurrentPinVerificationEvent(pin),
                );
                _textEditingController.clear();
              },
            );
          } else if (state is SaveNewPinState) {
            return AuthViews(
              textEditingController: _textEditingController,
              text: "addNPIN",
              onCompleted: (pin) {
                BlocProvider.of<ChangePinBloc>(context).add(
                  SaveNewPinEvent(pin),
                );
              },
            );
          }
          return Container();
        },
      ),
    );
  }
}
