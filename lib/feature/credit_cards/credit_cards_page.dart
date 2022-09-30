import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/core/widgets/loading_widget.dart';
import 'package:wallet_app/feature/credit_cards/bloc/credit_card_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/feature/credit_cards/widgets/app_bar.dart';
import 'package:wallet_app/feature/credit_cards/widgets/body.dart';

class CreditCardsPage extends StatefulWidget {
  const CreditCardsPage({Key? key}) : super(key: key);

  @override
  State<CreditCardsPage> createState() => _CreditCardsPageState();
}

class _CreditCardsPageState extends State<CreditCardsPage> {
  @override
  void initState() {
    super.initState();
    BlocProvider.of<CreditCardBloc>(context).add(LoadCreditCardsEvent());
  }

  _checkState(CreditCardState state) => state is CreditCardLoadedState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: ColorConstants.primaryColor,
      appBar: CCAppBar(),
      body: BlocBuilder<CreditCardBloc, CreditCardState>(
        builder: (context, state) =>
            _checkState(state) ? Body(state: state) : LoadingWidget(),
      ),
    );
  }
}
