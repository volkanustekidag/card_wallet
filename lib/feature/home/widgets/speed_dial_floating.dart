// feature/home/widgets/speed_dial_floating.dart - GetX Version
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:wallet_app/core/controllers/home_controller.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:easy_localization/easy_localization.dart';

class SpeedDialFloating extends StatelessWidget {
  const SpeedDialFloating({Key? key}) : super(key: key);

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
            Get.toNamed('/addCreditCard')
                ?.then((value) => Get.find<HomeController>().refreshData());
          },
          label: "addCC".tr(),
          child: const Icon(
            Icons.add_card,
            color: ColorConstants.secondaryColor,
          ),
        ),
        SpeedDialChild(
          onTap: () {
            Get.toNamed('/addIbanCard')
                ?.then((value) => Get.find<HomeController>().refreshData());
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
