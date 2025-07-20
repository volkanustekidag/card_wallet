import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wallet_app/core/controllers/home_controller.dart';
import 'package:easy_localization/easy_localization.dart';

class SpeedDialFloating extends StatelessWidget {
  const SpeedDialFloating({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      backgroundColor: context.theme.colorScheme.primary,
      foregroundColor: Colors.white,
      activeBackgroundColor: context.theme.colorScheme.secondary,
      activeForegroundColor: Colors.white,
      animatedIcon: AnimatedIcons.add_event,
      overlayColor: Colors.black,
      overlayOpacity: 0.4,
      spacing: 12,
      childPadding: EdgeInsets.all(8),
      spaceBetweenChildren: 8,
      elevation: 8,
      animationCurve: Curves.easeInOutCubic,
      animationDuration: Duration(milliseconds: 300),
      children: [
        SpeedDialChild(
          onTap: () {
            Get.toNamed('/addCreditCard')
                ?.then((value) => Get.find<HomeController>().refreshData());
          },
          label: "addCC".tr(),
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          labelBackgroundColor: context.theme.colorScheme.surface,
          backgroundColor: context.theme.colorScheme.surface,
          foregroundColor: context.theme.colorScheme.primary,
          elevation: 4,
          child: Icon(
            Icons.credit_card_rounded,
            size: 24,
          ),
        ),
        SpeedDialChild(
          onTap: () {
            Get.toNamed('/addIbanCard')
                ?.then((value) => Get.find<HomeController>().refreshData());
          },
          label: "addIC".tr(),
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          labelBackgroundColor: context.theme.colorScheme.surface,
          backgroundColor: context.theme.colorScheme.surface,
          foregroundColor: context.theme.colorScheme.secondary,
          elevation: 4,
          child: Icon(
            Icons.account_balance_rounded,
            size: 24,
          ),
        ),
      ],
    );
  }
}
