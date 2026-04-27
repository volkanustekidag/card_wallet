import 'package:flutter/material.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_bank_detector.dart';

/// Renders a small text-based network logo in the colour scheme used by the
/// real card brands. We deliberately avoid bundling SVG/PNG logos to keep the
/// app size down and to side-step trademark hassles — a stylised wordmark is
/// what most card-wallet apps render anyway.
class CardNetworkBadge extends StatelessWidget {
  final CardNetwork network;
  final double height;

  const CardNetworkBadge({
    Key? key,
    required this.network,
    this.height = 22,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final spec = _specFor(network);
    if (spec == null) return const SizedBox.shrink();

    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: height * 0.45),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(height * 0.25),
      ),
      child: Center(
        child: Text(
          spec.label,
          style: TextStyle(
            fontFamily: 'Poppins',
            color: spec.color,
            fontWeight: FontWeight.w800,
            fontSize: height * 0.55,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  static _NetworkSpec? _specFor(CardNetwork network) {
    switch (network) {
      case CardNetwork.visa:
        return const _NetworkSpec('VISA', Color(0xFF1A1F71));
      case CardNetwork.mastercard:
        return const _NetworkSpec('Mastercard', Color(0xFFEB001B));
      case CardNetwork.amex:
        return const _NetworkSpec('AMEX', Color(0xFF2E77BB));
      case CardNetwork.discover:
        return const _NetworkSpec('DISCOVER', Color(0xFFFF6000));
      case CardNetwork.dinersClub:
        return const _NetworkSpec('DINERS', Color(0xFF0079BE));
      case CardNetwork.jcb:
        return const _NetworkSpec('JCB', Color(0xFF0E4C96));
      case CardNetwork.unknown:
        return null;
    }
  }
}

class _NetworkSpec {
  final String label;
  final Color color;
  const _NetworkSpec(this.label, this.color);
}
