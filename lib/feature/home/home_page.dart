import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/core/widgets/loading_widget.dart';
import 'package:wallet_app/feature/home/bloc/home_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/feature/home/widgets/body.dart';
import 'package:wallet_app/feature/home/widgets/home_app_bar.dart';
import 'package:wallet_app/feature/home/widgets/speed_dial_floating.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    BlocProvider.of<HomeBloc>(context).add(LoadHomeContentEvent());
  }

  _checkState(HomeState state) => state is LoadedHomeContent;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        backgroundColor: ColorConstants.primaryColor,
        floatingActionButton: SpeedDialFloating(),
        appBar: HomeAppBar(),
        body: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) =>
              _checkState(state) ? HomeBody(state: state) : LoadingWidget(),
        ),
      ),
    );
  }
}
