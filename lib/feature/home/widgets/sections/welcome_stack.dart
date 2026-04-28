import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wallet_app/core/enums/card_limit_type.dart';
import 'package:wallet_app/feature/home/widgets/sections/add_card_navigator.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';

/// Single, illustrated empty state shown when the wallet has zero cards.
/// Three faux cards stacked at slight angles (the visual cue "this is
/// where your cards will live") plus a primary CTA. Replaces the three
/// separate DashedEmptyCards that used to take up ~600 dp.
class WelcomeStack extends StatelessWidget {
  const WelcomeStack({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final cardWidth = size.width.clamp(280, 400) * 0.62;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kSpaceLg,
        vertical: kSpaceLg,
      ),
      child: Column(
        children: [
          SizedBox(
            height: kWelcomeStackHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Back card — loyalty (right-tilted, dimmer)
                _PhantomCard(
                  width: cardWidth.toDouble(),
                  rotation: 0.08,
                  offsetY: -4,
                  offsetX: 32,
                  alpha: 0.42,
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.tertiary.withValues(alpha: 0.92),
                      colorScheme.tertiary.withValues(alpha: 0.55),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  icon: Icons.local_offer_rounded,
                ),
                // Mid card — IBAN (left-tilted)
                _PhantomCard(
                  width: cardWidth.toDouble(),
                  rotation: -0.07,
                  offsetY: 24,
                  offsetX: -28,
                  alpha: 0.7,
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.secondary.withValues(alpha: 0.95),
                      colorScheme.secondary.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  icon: Icons.account_balance_rounded,
                ),
                // Front card — credit (centered, fully opaque)
                _PhantomCard(
                  width: cardWidth.toDouble(),
                  rotation: 0,
                  offsetY: 56,
                  offsetX: 0,
                  alpha: 1,
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.78),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  icon: Icons.credit_card_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: kSpaceLg),
          Text(
            'walletAwaits'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: kSpaceXS),
          Text(
            'walletAwaitsSub'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'Poppins',
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: kSpaceLg),
          FilledButton.icon(
            onPressed: () => goToAddCard(
              context: context,
              type: CardLimitType.credit,
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(
              'addFirstCard'.tr(),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: kSpaceXL,
                vertical: kSpaceMd,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhantomCard extends StatelessWidget {
  final double width;
  final double rotation;
  final double offsetY;
  final double offsetX;
  final double alpha;
  final Gradient gradient;
  final IconData icon;

  const _PhantomCard({
    required this.width,
    required this.rotation,
    required this.offsetY,
    required this.offsetX,
    required this.alpha,
    required this.gradient,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(offsetX, offsetY),
      child: Transform.rotate(
        angle: rotation,
        child: Opacity(
          opacity: alpha,
          child: Container(
            width: width,
            height: width / kPaymentCardAspect,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(kSpaceLg),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Icon(
                  icon,
                  color: Colors.white.withValues(alpha: 0.75),
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
