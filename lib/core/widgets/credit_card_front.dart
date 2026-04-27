import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/linear_gradient_color.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/widgets/card_network_badge.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_bank_detector.dart';
import 'package:easy_localization/easy_localization.dart';

class CreditCardFront extends StatelessWidget {
  final CreditCard creditCard;
  const CreditCardFront({Key? key, required this.creditCard}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gradient =
        LinearGradients().linearGradientList[creditCard.cardColorId];
    final bankName = creditCard.bankName.isNotEmpty
        ? creditCard.bankName
        : 'unknownBank'.tr();

    final cardNumber = _formatCardNumber(creditCard.creditCardNumber);
    final cardHolder =
        creditCard.cardHolder.isNotEmpty ? creditCard.cardHolder : '----';
    final expiration = creditCard.expirationDate.isNotEmpty
        ? creditCard.expirationDate
        : 'MM/YY';

    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(bankName),
              const SizedBox(height: 10),
              Image.asset(
                "assets/images/chip.png",
                width: 48,
              ),
              const SizedBox(height: 16),
              Text(
                cardNumber,
                style: TextStyle(fontFamily: 'Poppins', 
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      offset: const Offset(0, 2),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildMetaInformation(cardHolder, expiration),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildHeader(String bankName) {
    final network = CardBankDetector.networkFor(creditCard.creditCardNumber);
    return Row(
      children: [
        Expanded(
          child: Text(
            bankName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: 'Poppins',
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
              letterSpacing: 0.4,
            ),
          ),
        ),
        if (network != CardNetwork.unknown) ...[
          CardNetworkBadge(network: network, height: 22),
          const SizedBox(width: 8),
        ],
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.wifi_rounded, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildMetaInformation(String cardHolder, String expiration) {
    final labelStyle = TextStyle(fontFamily: 'Poppins', 
      color: Colors.white,
      fontSize: 11,
      letterSpacing: 1.2,
      fontWeight: FontWeight.w500,
    );
    final valueStyle = TextStyle(fontFamily: 'Poppins', 
      color: Colors.white,
      fontSize: 16,
      letterSpacing: 1.5,
      fontWeight: FontWeight.w600,
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "hName".tr().toUpperCase(),
                style: labelStyle,
              ),
            ),
            Text(
              "valid".tr().toUpperCase(),
              style: labelStyle,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                cardHolder,
                style: valueStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              expiration,
              style: valueStyle,
            ),
          ],
        ),
      ],
    );
  }

  String _formatCardNumber(String number) {
    final sanitized = number.replaceAll(RegExp(r'\s+'), '');
    if (sanitized.isEmpty) return '•••• •••• •••• ••••';

    final buffer = StringBuffer();
    for (var i = 0; i < sanitized.length; i++) {
      buffer.write(sanitized[i]);
      final isLast = i == sanitized.length - 1;
      if (!isLast && (i + 1) % 4 == 0) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }
}
