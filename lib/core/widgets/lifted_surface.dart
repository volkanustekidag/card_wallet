import 'package:flutter/material.dart';
import 'package:wallet_app/core/styles/shadows.dart';

/// Shared "lifted" surface wrapper. Applies the app's standard
/// top-edge highlight gradient and soft drop shadow over any base color,
/// so box/panel/tile components read as gently raised from the background.
///
/// Used by the home action grid, settings cards, premium strip, etc. Card
/// faces (credit/IBAN) and filled buttons intentionally do NOT use this —
/// they have their own visual identity.
class LiftedSurface extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final bool topHighlight;
  final bool dropShadow;
  final Clip clipBehavior;

  const LiftedSurface({
    Key? key,
    required this.child,
    this.color,
    this.gradient,
    this.borderRadius,
    this.padding,
    this.margin,
    this.border,
    this.boxShadow,
    this.topHighlight = true,
    this.dropShadow = true,
    this.clipBehavior = Clip.antiAlias,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveRadius = borderRadius ?? BorderRadius.circular(18);
    final baseColor = color ?? colorScheme.surfaceContainerHighest;

    final Gradient effectiveGradient = gradient ??
        (topHighlight
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.alphaBlend(
                    Colors.white.withValues(alpha: 0.08),
                    baseColor,
                  ),
                  baseColor,
                ],
                stops: const [0.0, 0.35],
              )
            : LinearGradient(colors: [baseColor, baseColor]));

    return Container(
      margin: margin,
      padding: padding,
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        gradient: effectiveGradient,
        borderRadius: effectiveRadius,
        border: border,
        boxShadow:
            boxShadow ?? (dropShadow ? Shadows.shadowLifted : null),
      ),
      child: child,
    );
  }
}
