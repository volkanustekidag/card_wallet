import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/constants/paddings.dart';
import 'package:wallet_app/feature/home/bloc/home_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sizer/sizer.dart';

class RowTitles extends StatelessWidget {
  final title;
  final route;
  const RowTitles({
    Key? key,
    required this.title,
    required this.route,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: PaddingConstants.high(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "${title}".tr(),
            style: TextStyle(
                fontWeight: FontWeight.w400,
                color: Colors.white,
                fontSize: 13.sp),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, route).then(
                (value) => BlocProvider.of<HomeBloc>(context).add(
                  LoadHomeContentEvent(),
                ),
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
