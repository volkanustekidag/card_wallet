// feature/home/widgets/row_titles.dart - GetX Version
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/controllers/home_controller.dart';
import 'package:wallet_app/core/constants/paddings.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sizer/sizer.dart';

class RowTitles extends StatelessWidget {
  final String title;
  final String route;

  const RowTitles({
    Key? key,
    required this.title,
    required this.route,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const PaddingConstants.high(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.tr(),
            style: TextStyle(
                fontWeight: FontWeight.w400,
                color: Colors.white,
                fontSize: 13.sp),
          ),
          GestureDetector(
            onTap: () {
              Get.toNamed(route)?.then(
                (value) => Get.find<HomeController>().refreshData(),
              );
            },
            child: Text(
              "seeAll".tr(),
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }
}
