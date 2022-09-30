import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sizer/sizer.dart';
import 'package:wallet_app/core/constants/app_images.dart';

class EmptyListInfo extends StatelessWidget {
  const EmptyListInfo({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            AppImages().cardIcon,
            width: 20.w,
          ),
          Text(
            "emptyList".tr(),
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w400,
                fontSize: 15.sp),
          )
        ],
      ),
    );
  }
}
