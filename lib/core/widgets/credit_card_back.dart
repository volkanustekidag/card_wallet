import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:wallet_app/core/constants/linear_gradient_color.dart';
import 'package:wallet_app/core/constants/paddings.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';

class CreditCardBack extends StatelessWidget {
  final CreditCard creditCard;
  const CreditCardBack({
    Key? key,
    required this.creditCard,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Container(
            height: 28.h,
            decoration: BoxDecoration(
              gradient:
                  LinearGradients().linearGradientList[creditCard.cardColorId],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
                padding: PaddingConstants.extraHigh(),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 40,
                          width: MediaQuery.of(context).size.width * 0.7,
                          decoration: const BoxDecoration(color: Colors.white),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              creditCard.cvc2,
                              style: GoogleFonts.courierPrime(
                                  color: Colors.black, fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                    ]))));
  }
}
