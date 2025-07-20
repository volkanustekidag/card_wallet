import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:wallet_app/core/constants/linear_gradient_color.dart';
import 'package:wallet_app/core/constants/paddings.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/styles/shadows.dart';

class CreditCardFront extends StatelessWidget {
  final CreditCard creditCard;
  const CreditCardFront({Key? key, required this.creditCard}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 28.h,
        width: 90.h,
        decoration: BoxDecoration(
          gradient:
              LinearGradients().linearGradientList[creditCard.cardColorId],
          borderRadius: BorderRadius.circular(15),
          boxShadow: Shadows.shadowMedium,
        ),
        child: Padding(
          padding: PaddingConstants.extraHigh(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  creditCard.bankName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  "assets/images/chip.png",
                  width: 15.w,
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(creditCard.creditCardNumber,
                    style: GoogleFonts.courierPrime(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 25)),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _buildDetailColumn("hName".tr(), creditCard.cardHolder),
                _buildDetailColumn("valid".tr(), creditCard.expirationDate),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Column _buildDetailColumn(title, value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.courierPrime(
                color: Colors.white,
                letterSpacing: 1,
                fontWeight: FontWeight.w500,
                fontSize: 10)),
        Text(value,
            style: GoogleFonts.courierPrime(
                color: Colors.white,
                letterSpacing: 1,
                fontWeight: FontWeight.w500,
                fontSize: 16)),
      ],
    );
  }
}
