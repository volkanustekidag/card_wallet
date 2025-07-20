import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:easy_localization/easy_localization.dart';

class AddIbanCardWidget extends StatelessWidget {
  final IbanCard ibanCard;
  const AddIbanCardWidget({Key? key, required this.ibanCard}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 25.h,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [
              Color(0xFF35383E),
              Color(0xFF3C424E),
            ]),
            borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

  Widget _buildColumnCardItem(label, value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
