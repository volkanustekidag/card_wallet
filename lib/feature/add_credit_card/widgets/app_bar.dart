import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wallet_app/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/feature/add_credit_card/bloc/add_credit_bloc.dart';
import 'package:sizer/sizer.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/feature/credit_cards/bloc/credit_card_bloc.dart';

class AddCreditAppBar extends StatelessWidget with PreferredSizeWidget {
  const AddCreditAppBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        onPressed: () {
          BlocProvider.of<AddCreditBloc>(context).add(
            SaveCreditCardEvent(
              CreditCard(1, "", "", "", "", "", 1),
            ),
          );

          Navigator.pop(context);
        },
        icon: const Icon(
          Icons.arrow_back_ios,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: () {
            BlocProvider.of<AddCreditBloc>(context).add(
              AddNewCreditCardEvent(),
            );

            BlocProvider.of<CreditCardBloc>(context).add(
              LoadCreditCardsEvent(),
            );

            context.showSnackBarInfo(context, Colors.green, "addNCC");

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
      backgroundColor: Colors.transparent,
      title: Text(
        "addCC".tr(),
        style: GoogleFonts.montserrat(
            color: Colors.white, fontWeight: FontWeight.w500),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(8.h);
}
