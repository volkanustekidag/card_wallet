import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wallet_app/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/feature/add_iban_card/bloc/add_iban_card_bloc.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:sizer/sizer.dart';
import 'package:easy_localization/easy_localization.dart';

class AddIbanAppBar extends StatelessWidget with PreferredSizeWidget {
  const AddIbanAppBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        onPressed: () {
          BlocProvider.of<AddIbanCardBloc>(context).add(
            SaveIbanCardEvent(
              IbanCard("", "", "", "", 1),
            ),
          );
          Navigator.pop(context);
        },
        icon: const Icon(
          Icons.arrow_back_ios,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            BlocProvider.of<AddIbanCardBloc>(context).add(
              AddNewIbanCardEvent(),
            );
            context.showSnackBarInfo(context, Colors.green, "addNIC");

            Navigator.pop(
              context,
            );
          },
          icon: const Icon(
            Icons.add_card,
            color: Colors.white,
          ),
        )
      ],
      title: Text(
        "addIC".tr(),
        style: GoogleFonts.montserrat(
            color: Colors.white, fontWeight: FontWeight.w400),
      ),
    );
  }

  @override
  // TODO: implement preferredSize
  Size get preferredSize => Size.fromHeight(8.h);
}
