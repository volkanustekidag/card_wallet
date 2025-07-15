import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:wallet_app/core/constants/linear_gradient_color.dart';
import 'package:wallet_app/core/constants/paddings.dart';
import 'package:wallet_app/core/controllers/add_credit_card_controller.dart';

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
          padding: const PaddingConstants.normal(),
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                controller.updateCardField("cardColorId", index);
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
