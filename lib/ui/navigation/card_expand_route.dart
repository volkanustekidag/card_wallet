import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallet_app/ui/card/card_material.dart';
import 'package:wallet_app/ui/tokens.dart';

/// Checkout background for a card: its own colour, lit from the top. The
/// expanding card ends on exactly this, so the page lands without a seam.
BoxDecoration checkoutBackground(CardMaterial m) => BoxDecoration(
      gradient: RadialGradient(
        center: const Alignment(0, -1),
        radius: 1.35,
        colors: [m.colors[m.colors.length > 2 ? 2 : 0], m.base, m.colors.first],
        stops: const [0, 0.45, 1],
      ),
    );

/// Global rect of [context]'s box, or null when it isn't laid out or is
/// (nearly) the whole screen, where growing from it would look like nothing.
Rect? originRectOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize || !box.attached) return null;
  final rect = box.localToGlobal(Offset.zero) & box.size;
  final screen = MediaQuery.sizeOf(context);
  if (rect.width * rect.height > screen.width * screen.height * 0.6) {
    return null;
  }
  return rect;
}

/// Opens Checkout from the card that was tapped: the card grows to fill the
/// screen in its own colour, then the page shows and its barcode rises in
/// ([CheckoutRiseIn]). Going back the page settles away instead of shrinking
/// to the card, which may have moved in the meantime (use reorders Home).
///
/// No [origin], or reduced motion: a plain fade.
class CardExpandRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;
  final Rect? origin;
  final CardMaterial material;
  final double originRadius;

  CardExpandRoute({
    required this.builder,
    required this.material,
    this.origin,
    this.originRadius = 14,
    super.settings,
  });

  @override
  bool get opaque => true;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 460);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 240);

  @override
  TickerFuture didPush() {
    if (origin != null) HapticFeedback.lightImpact();
    return super.didPush();
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) =>
      builder(context);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    final reduce = MediaQuery.of(context).disableAnimations;
    final from = origin;
    if (from == null || reduce) {
      return FadeTransition(opacity: animation, child: child);
    }
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, page) {
        final v = animation.value;
        // Back: the page fades and settles a little; Home shows through.
        if (animation.status == AnimationStatus.reverse) {
          final t = Curves.easeIn.transform(1 - v);
          return Opacity(
            opacity: 1 - t,
            child: Transform.scale(scale: 1 - 0.04 * t, child: page),
          );
        }
        final size = MediaQuery.sizeOf(context);
        final grow =
            CwMotion.standard.transform(const Interval(0, 0.72).transform(v));
        final rect = Rect.lerp(from, Offset.zero & size, grow)!;
        final radius = lerpDouble(originRadius, 0, grow)!;
        final show = const Interval(0.5, 1, curve: Curves.easeOut).transform(v);
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fromRect(
              rect: rect,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(math.max(0, radius)),
                child: DecoratedBox(decoration: checkoutBackground(material)),
              ),
            ),
            if (show > 0) Opacity(opacity: show, child: page),
          ],
        );
      },
    );
  }
}

/// Rises the Checkout content into place as the page arrives (any route
/// that opens it; nothing to do once the route has settled).
class CheckoutRiseIn extends StatelessWidget {
  final Widget child;
  const CheckoutRiseIn({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context)?.animation;
    if (route == null || MediaQuery.of(context).disableAnimations) {
      return child;
    }
    final rise = CurvedAnimation(
      parent: route,
      curve: const Interval(0.55, 1, curve: Curves.easeOutCubic),
      reverseCurve: const Threshold(0),
    );
    return AnimatedBuilder(
      animation: rise,
      child: child,
      builder: (context, c) => Transform.translate(
        offset: Offset(0, 48 * (1 - rise.value)),
        child: c,
      ),
    );
  }
}
