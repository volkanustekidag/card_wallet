import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/linear_gradient_color.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/widgets/bank_logo.dart';
import 'package:wallet_app/core/widgets/card_network_badge.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_bank_detector.dart';
import 'package:easy_localization/easy_localization.dart';

class CreditCardFront extends StatelessWidget {
  final CreditCard creditCard;
  final bool maskNumber;
  const CreditCardFront({
    Key? key,
    required this.creditCard,
    this.maskNumber = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gradient =
        LinearGradients().linearGradientList[creditCard.cardColorId];
    final bankName = creditCard.bankName.isNotEmpty
        ? creditCard.bankName
        : 'unknownBank'.tr();

    final cardNumber = maskNumber
        ? _maskCardNumber(creditCard.creditCardNumber)
        : _formatCardNumber(creditCard.creditCardNumber);
    final cardHolder =
        creditCard.cardHolder.isNotEmpty ? creditCard.cardHolder : '----';
    final expiration = creditCard.expirationDate.isNotEmpty
        ? creditCard.expirationDate
        : 'MM/YY';
    final network = CardBankDetector.networkFor(creditCard.creditCardNumber);

    return SizedBox.expand(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 0.6,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo only renders if BankLogo successfully loaded an
                  // image (cached or live). On miss/offline it returns
                  // SizedBox.shrink — bank name keeps its place on its own.
                  // The logo follows the *card number*, not the bank-name
                  // field, so user edits to the name don't kill the logo.
                  BankLogo(
                    cardNumber: creditCard.creditCardNumber,
                    bankName: creditCard.bankName,
                    size: 20,
                    chrome: true,
                  ),
                  if (CardBankDetector.bankDomainFor(
                          CardBankDetector.detect(
                                  creditCard.creditCardNumber)) !=
                          null ||
                      CardBankDetector.bankDomainFor(creditCard.bankName) !=
                          null)
                    const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bankName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  if (network != CardNetwork.unknown) ...[
                    const SizedBox(width: 8),
                    CardNetworkBadge(network: network, height: 26),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Image.asset(
                "assets/images/chip.png",
                width: 38,
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  cardNumber,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 1.4,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        offset: const Offset(0, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildMetaRow(cardHolder, expiration),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildMetaRow(
    String cardHolder,
    String expiration,
  ) {
    final labelStyle = TextStyle(
      fontFamily: 'Poppins',
      color: Colors.white.withValues(alpha: 0.7),
      fontSize: 9,
      letterSpacing: 1,
      fontWeight: FontWeight.w500,
    );
    const valueStyle = TextStyle(
      fontFamily: 'Poppins',
      color: Colors.white,
      fontSize: 12,
      letterSpacing: 1,
      fontWeight: FontWeight.w600,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("hName".tr().toUpperCase(), style: labelStyle),
              const SizedBox(height: 2),
              Text(
                cardHolder,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: valueStyle,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("valid".tr().toUpperCase(), style: labelStyle),
            const SizedBox(height: 2),
            Text(expiration, style: valueStyle),
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

  /// Mask all but the last 4 digits of the card number, keeping the
  /// "•••• •••• •••• 1234" grouping so the layout stays steady.
  String _maskCardNumber(String number) {
    final sanitized = number.replaceAll(RegExp(r'\s+'), '');
    if (sanitized.isEmpty) return '•••• •••• •••• ••••';
    if (sanitized.length <= 4) return sanitized;

    final tail = sanitized.substring(sanitized.length - 4);
    final hiddenLen = sanitized.length - 4;
    final buffer = StringBuffer();
    for (var i = 0; i < hiddenLen; i++) {
      buffer.write('•');
      if ((i + 1) % 4 == 0) buffer.write(' ');
    }
    buffer.write(tail);
    return buffer.toString();
  }
}
