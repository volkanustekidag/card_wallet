import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/constants/linear_gradient_color.dart';
import 'package:wallet_app/core/constants/paddings.dart';
import 'package:wallet_app/feature/add_credit_card/bloc/add_credit_bloc.dart';
import 'package:sizer/sizer.dart';

class ColorsListView extends StatelessWidget {
  const ColorsListView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        height: 50,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: LinearGradients().linearGradientList.length,
          padding: PaddingConstants.normal(),
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                BlocProvider.of<AddCreditBloc>(context).add(
                  UpdateCreditCardEvent(index, "cardColorId"),
                );
              },
              child: Container(
                width: 10.w,
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1),
                    gradient: LinearGradients().linearGradientList[index],
                    shape: BoxShape.circle),
              ),
            );
          },
        ),
      ),
    );
  }
}
