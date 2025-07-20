import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart' hide Trans;
import 'package:google_fonts/google_fonts.dart';
import 'package:wallet_app/core/controllers/home_controller.dart';
import 'package:easy_localization/easy_localization.dart';

class RowTitles extends StatelessWidget {
  final String title;
  final String route;
  final String iconPath;
  const RowTitles({
    Key? key,
    required this.title,
    required this.route,
    required this.iconPath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 38),
      child: Row(
        children: [
          SvgPicture.asset(
            iconPath,
            height: 24,
            width: 24,
            color: context.theme.colorScheme.onSurface,
          ),
          SizedBox(width: 8),
          Text(
            title.tr(),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Get.toNamed(route)?.then(
                (value) => Get.find<HomeController>().refreshData(),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "seeAll".tr(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: context.theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
