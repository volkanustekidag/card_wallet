import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:wallet_app/core/constants/paddings.dart';
import 'package:wallet_app/domain/models/iban_card_model/iban_card.dart';
import 'package:easy_localization/easy_localization.dart';

class IbanCards extends StatelessWidget {
  final IbanCard ibanCard;
  const IbanCards({Key? key, required this.ibanCard}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: PaddingConstants.normal(),
      child: Container(
        width: 90.w,
        height: 25.h,
        decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [
              Color.fromARGB(255, 124, 124, 124),
              Color.fromARGB(255, 97, 97, 97),
            ]),
            borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: PaddingConstants.symmetricNormalVertical(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildColumnCardItem("hName".tr(), ibanCard.cardHolder),
              _buildColumnCardItem("IBAN", ibanCard.iban),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildColumnCardItem("sCode".tr(), ibanCard.swiftCode),
                  _buildColumnCardItem("bName".tr(), ibanCard.bankName)
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Padding _buildColumnCardItem(label, value) {
    return Padding(
      padding: PaddingConstants.symmetricHighVertical(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 8.sp,
                color: Colors.white70,
              )),
          Text(
            value,
            style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white),
          ),
        ],
      ),
    );
  }
}
