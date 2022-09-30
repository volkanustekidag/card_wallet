import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/feature/home/bloc/home_bloc.dart';
import 'package:sizer/sizer.dart';

class HomeAppBar extends StatelessWidget with PreferredSizeWidget {
  const HomeAppBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: ColorConstants.primaryColor,
      actions: [
        IconButton(
            onPressed: () {
              Navigator.pushNamed(context, "settings").then(
                (value) => BlocProvider.of<HomeBloc>(context).add(
                  LoadHomeContentEvent(),
                ),
              );
            },
            icon: Icon(
              Icons.settings,
              size: 20.sp,
              color: Colors.white,
            ))
      ],
      elevation: 0,
      title: Column(
        children: [
          Text(
            "CARD\nWALLET",
            style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 25.sp,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
      toolbarHeight: 100,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(100);
}
