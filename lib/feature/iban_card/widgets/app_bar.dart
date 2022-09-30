import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/feature/iban_card/bloc/iban_card_bloc.dart';
import 'package:sizer/sizer.dart';
import 'package:easy_localization/easy_localization.dart';

class IbanCardsAppBar extends StatelessWidget with PreferredSizeWidget {
  const IbanCardsAppBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                ColorConstants.primaryColor.withOpacity(0.5),
                ColorConstants.primaryColor.withOpacity(0.1),
              ]),
        ),
      ),
      actions: [
        IconButton(
            onPressed: () {
              Navigator.pushNamed(context, "addIbanCard").then((value) =>
                  BlocProvider.of<IbanCardBloc>(context)
                      .add(LoadIbanCardEvent()));
            },
            icon: Icon(
              Icons.add,
              color: Colors.white,
              size: 8.w,
            ))
      ],
      leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          )),
      title: Text(
        "IC".tr(),
        style: GoogleFonts.montserrat(
            color: Colors.white, fontWeight: FontWeight.w500),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(8.h);
}
