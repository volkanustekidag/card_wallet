import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';

/// Single, illustrated empty state shown when the wallet has zero cards.
/// Three faux cards stacked at slight angles cue the user that "this is
/// where your cards will live"; the QuickActionRail directly underneath
/// already exposes the three add-card actions, so no inline CTA is
/// needed here.
class WelcomeStack extends StatelessWidget {
  const WelcomeStack({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final cardWidth = (size.width.clamp(280, 400) * 0.46).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        kSpaceLg,
        kSpaceMd,
        kSpaceLg,
        kSpaceSm,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 168,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _PhantomCard(
                  width: cardWidth,
                  rotation: 0.08,
                  offsetY: -6,
                  offsetX: 26,
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
                _PhantomCard(
                  width: cardWidth,
                  rotation: -0.07,
                  offsetY: 14,
                  offsetX: -22,
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
                _PhantomCard(
                  width: cardWidth,
                  rotation: 0,
                  offsetY: 36,
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
          const SizedBox(height: kSpaceMd),
          Text(
            'walletAwaits'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            'walletAwaitsSub'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'Poppins',
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
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
