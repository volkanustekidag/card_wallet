import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/components/auth_component.dart';
import 'package:wallet_app/feature/auth/bloc/authentication_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({Key? key}) : super(key: key);

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  TextEditingController _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    BlocProvider.of<AuthenticationBloc>(context).add(
      CheckHavePasswordEvent(),
    );
  }

  void _checkHavePassword() {
    BlocProvider.of<AuthenticationBloc>(context).add(
      CheckHavePasswordEvent(),
    );
    context.showSnackBarInfo(context, Colors.red, "loginSnackText");
  }

  void _navigateToHome() {
    Navigator.pushReplacementNamed(context, "home");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.primaryColor,
      resizeToAvoidBottomInset: true,
      body: BlocConsumer<AuthenticationBloc, AuthenticationState>(
        listener: (context, state) {
          if (state is SuccessfulLoginState)
            _navigateToHome();
          else if (state is FaiulerLoginState) _checkHavePassword();
        },
        builder: (context, state) {
          if (state is RequiredRegisterState) {
            return AuthViews(
              textEditingController: _textEditingController,
              text: "createPin",
              onCompleted: (password) {
                BlocProvider.of<AuthenticationBloc>(context).add(
                  RegisterEvent(password),
                );
              },
            );
          }
          if (state is AuthenticationInitial || state is FaiulerLoginState) {
            _textEditingController.clear();
            return AuthViews(
              textEditingController: _textEditingController,
              text: "enterPin",
              onCompleted: (password) {
                BlocProvider.of<AuthenticationBloc>(context).add(
                  LoginEvent(password),
                );
                _textEditingController.clear();
              },
            );
          }

          return Container();
        },
      ),
    );
  }
}
