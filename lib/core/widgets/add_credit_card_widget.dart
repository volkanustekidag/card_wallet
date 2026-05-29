import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/linear_gradient_color.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/widgets/bank_logo.dart';
import 'package:wallet_app/core/widgets/card_network_badge.dart';
import 'package:wallet_app/core/widgets/credit_card_front.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_bank_detector.dart';

/// Live preview shown while the user fills the credit-card form. Wraps
/// the shared [CreditCardFront] for the full layout and adds a compact
/// pill (bank + last-4 + network badge) for the collapsed state.
///
/// [collapse] crossfades between the two: 0.0 = full card, 1.0 = pill.
/// Lets the add page shrink the preview on scroll without losing the
/// "what bank / which card" identification.
class AddCreditCardWidget extends StatelessWidget {
  final CreditCard creditCard;
  final double collapse;

  const AddCreditCardWidget({
    Key? key,
    required this.creditCard,
    this.collapse = 0.0,
  }) : super(key: key);

  String _lastFour(String value) {
    final clean = value.replaceAll(RegExp(r'\s+'), '');
    if (clean.isEmpty) return '••••';
    if (clean.length < 4) return clean;
    return clean.substring(clean.length - 4);
  }

  bool _hasBankLogo() {
    return CardBankDetector.bankDomainFor(creditCard.bankName) != null ||
        CardBankDetector.bankDomainFor(
                CardBankDetector.detect(creditCard.creditCardNumber)) !=
            null;
  }

  @override
  Widget build(BuildContext context) {
    final t = collapse.clamp(0.0, 1.0);

    // Crossfade: expanded fades 0 -> 0.55, compact fades 0.45 -> 1. Slight
    // overlap keeps the hand-off smooth.
    final expandedOpacity = (1 - t / 0.55).clamp(0.0, 1.0);
    final compactOpacity = ((t - 0.45) / 0.55).clamp(0.0, 1.0);

    final gradient = LinearGradients()
        .linearGradientList[creditCard.cardColorId
            .clamp(0, LinearGradients().linearGradientList.length - 1)];

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 0.6,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 26,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full-size card preview pinned to the top with its natural
            // 1.586 aspect ratio. As the parent shrinks past it, the
            // bottom gets clipped — but it's already faded out by then.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AspectRatio(
                aspectRatio: 1.586,
                child: Opacity(
                  opacity: expandedOpacity,
                  child: CreditCardFront(creditCard: creditCard),
                ),
              ),
            ),
            // Compact pill fills whatever height the parent gives us.
            Positioned.fill(
              child: Opacity(
                opacity: compactOpacity,
                child: _CompactLayout(
                  creditCard: creditCard,
                  hasLogo: _hasBankLogo(),
                  lastFour: _lastFour(creditCard.creditCardNumber),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactLayout extends StatelessWidget {
  final CreditCard creditCard;
  final bool hasLogo;
  final String lastFour;

  const _CompactLayout({
    required this.creditCard,
    required this.hasLogo,
    required this.lastFour,
  });

  @override
  Widget build(BuildContext context) {
    final hasBank = creditCard.bankName.trim().isNotEmpty;
    final hasNumber = creditCard.creditCardNumber.replaceAll(' ', '').isNotEmpty;
    final network = CardBankDetector.networkFor(creditCard.creditCardNumber);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(4),
            child: hasLogo
                ? BankLogo(
                    cardNumber: creditCard.creditCardNumber,
                    bankName: creditCard.bankName,
                    size: 24,
                  )
                : const Icon(
                    Icons.credit_card_rounded,
                    color: Color(0xFF1A1D24),
                    size: 18,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasBank ? creditCard.bankName : 'unknownBank'.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: hasBank
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            hasNumber ? '•• $lastFour' : '•• ••••',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: hasNumber
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.55),
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(width: 10),
          if (network != CardNetwork.unknown)
            CardNetworkBadge(network: network, height: 16)
          else
            Text(
              'creditCardLabel'.tr().toUpperCase(),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.8),
                letterSpacing: 1,
              ),
            ),
        ],
      ),
    );
  }
}
