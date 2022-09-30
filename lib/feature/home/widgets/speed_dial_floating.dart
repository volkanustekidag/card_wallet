import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/feature/home/bloc/home_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

class SpeedDialFloating extends StatelessWidget {
  const SpeedDialFloating({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      backgroundColor: ColorConstants.secondaryColor,
      animatedIcon: AnimatedIcons.add_event,
      overlayColor: Colors.transparent,
      overlayOpacity: 0.3,
      children: [
        SpeedDialChild(
          onTap: () {
            Navigator.pushNamed(context, "addCreditCard").then((value) =>
                BlocProvider.of<HomeBloc>(context).add(LoadHomeContentEvent()));
          },
          label: "addCC".tr(),
          child: const Icon(
            Icons.add_card,
            color: ColorConstants.secondaryColor,
          ),
        ),
        SpeedDialChild(
          onTap: () {
            Navigator.pushNamed(context, "addIbanCard").then((value) =>
                BlocProvider.of<HomeBloc>(context).add(LoadHomeContentEvent()));
          },
          label: "addIC".tr(),
          child: const Icon(
            Icons.add_box,
            color: ColorConstants.secondaryColor,
          ),
        ),
      ],
    );
  }
}
