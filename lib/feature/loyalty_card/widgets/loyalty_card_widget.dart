import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/linear_gradient_color.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/utils/loyalty_brand_resolver.dart';
import 'package:wallet_app/core/widgets/bank_logo.dart';

/// Hero tag shared between the [LoyaltyCardWidget] in the listing and the
/// gradient shell of the detail page. Centralised so both ends agree on
/// the same string.
String loyaltyCardHeroTag(LoyaltyCard card) => 'loyalty-card-${card.id}';

/// Mini list-row card preview for loyalty cards. Tapping shows the
/// fullscreen barcode (handled by the parent). The gradient shell is
/// wrapped in a [Hero] so the detail page can morph from this card.
class LoyaltyCardWidget extends StatelessWidget {
  final LoyaltyCard card;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const LoyaltyCardWidget({
    Key? key,
    required this.card,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gradients = LinearGradients().linearGradientList;
    final gradient = gradients[card.colorId.clamp(0, gradients.length - 1)];
    final brand =
        (card.brand?.isNotEmpty ?? false) ? card.brand! : card.name;
    final hasLogo = LoyaltyBrandResolver.domainFor(brand) != null;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Hero(
          tag: loyaltyCardHeroTag(card),
          flightShuttleBuilder: (
            flightContext,
            animation,
            direction,
            fromContext,
            toContext,
          ) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                // Push: 20 → 0 (card → full-screen). Pop is the inverse.
                final t = direction == HeroFlightDirection.push
                    ? animation.value
                    : 1 - animation.value;
                final radius = 20 * (1 - t);
                return Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(radius),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withValues(alpha: 0.16 * (1 - t)),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasLogo)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(7),
                      child: BankLogo(loyaltyBrand: brand, size: 30),
                    )
                  else
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_offer_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (card.brand != null && card.brand!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            card.brand!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          _maskBarcode(card.barcode),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            letterSpacing: 1.4,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.qr_code_2_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _maskBarcode(String raw) {
    if (raw.length <= 8) return raw;
    final visible = raw.substring(raw.length - 4);
    return '••••  $visible';
  }
}
