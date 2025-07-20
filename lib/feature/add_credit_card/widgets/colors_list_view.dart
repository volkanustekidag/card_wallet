import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:wallet_app/core/constants/linear_gradient_color.dart';
import 'package:wallet_app/feature/add_credit_card/controller/add_credit_card_controller.dart';

class ColorsListView extends StatelessWidget {
  const ColorsListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AddCreditCardController>();

    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        height: 50,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: LinearGradients().linearGradientList.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                controller.updateCardField("cardColorId", index);
              },
              child: Container(
                margin: index == 0
                    ? EdgeInsets.only(
                        left: 16,
                        right: 8,
                      )
                    : EdgeInsets.only(right: 8),
                width: 10.w,
                decoration: BoxDecoration(
                    border: Border.all(width: 1),
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
