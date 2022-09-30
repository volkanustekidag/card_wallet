import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/core/widgets/loading_widget.dart';
import 'package:wallet_app/feature/iban_card/bloc/iban_card_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/feature/iban_card/widgets/app_bar.dart';
import 'package:wallet_app/feature/iban_card/widgets/body.dart';

class IbanCardsPage extends StatefulWidget {
  const IbanCardsPage({Key? key}) : super(key: key);

  @override
  State<IbanCardsPage> createState() => _IbanCardsPageState();
}

class _IbanCardsPageState extends State<IbanCardsPage> {
  @override
  void initState() {
    super.initState();
    BlocProvider.of<IbanCardBloc>(context).add(LoadIbanCardEvent());
  }

  bool _checkState(IbanCardState state) => state is IbanCardLoadedState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: ColorConstants.primaryColor,
      appBar: IbanCardsAppBar(),
      body: BlocBuilder<IbanCardBloc, IbanCardState>(
        builder: (context, state) =>
            _checkState(state) ? Body(state: state) : LoadingWidget(),
      ),
    );
  }
}
