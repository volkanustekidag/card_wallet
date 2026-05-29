import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/styles/shadows.dart';

class IbanCardWidget extends StatelessWidget {
  final IbanCard ibanCard;
  const IbanCardWidget({Key? key, required this.ibanCard}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.58,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [
            Color(0xFF35383E),
            Color(0xFF3C424E),
          ]),
          boxShadow: Shadows.shadowMedium,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
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
                  _buildColumnCardItem("bName".tr(), ibanCard.bankName),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColumnCardItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
