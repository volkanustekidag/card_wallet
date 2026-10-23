import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

enum CwButtonKind { primary, secondary, ghost, destructive, inverse }

/// The one button. Primary = brand fill, secondary = surface, ghost = text,
/// inverse = white on dark stage screens (onboarding, paywall, checkout).
class CwButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final CwButtonKind kind;
  final CwIcons? icon;
  final bool loading;
  final bool expand;
  final double height;

  const CwButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.kind = CwButtonKind.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.height = 54,
  });

  const CwButton.secondary(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.height = 50,
  }) : kind = CwButtonKind.secondary;

  const CwButton.ghost(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.height = 44,
  }) : kind = CwButtonKind.ghost;

  @override
  State<CwButton> createState() => _CwButtonState();
}

class _CwButtonState extends State<CwButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final enabled = widget.onPressed != null && !widget.loading;

    Color bg;
    Color fg;
    List<BoxShadow> shadow = const [];
    switch (widget.kind) {
      case CwButtonKind.primary:
        bg = c.brand;
        fg = c.onBrand;
        break;
      case CwButtonKind.inverse:
        bg = Colors.white;
        fg = const Color(0xFF0B0C0F);
        break;
      case CwButtonKind.secondary:
        bg = c.surface;
        fg = c.ink;
        shadow = CwElevation.e1(context);
        break;
      case CwButtonKind.ghost:
        bg = Colors.transparent;
        fg = c.mute;
        break;
      case CwButtonKind.destructive:
        bg = c.dangerSoft;
        fg = c.danger;
        break;
    }
    if (!enabled && widget.kind != CwButtonKind.ghost) {
      bg = c.surface2;
      fg = c.mute;
    }

    final content = widget.loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CupertinoActivityIndicator(color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                CwIcon(widget.icon!, size: CwIconSize.m, color: fg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (widget.kind == CwButtonKind.ghost
                          ? CwType.callout.copyWith(fontWeight: FontWeight.w600)
                          : CwType.headline)
                      .copyWith(color: fg),
                ),
              ),
            ],
          );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: CwMotion.fast,
          curve: CwMotion.standard,
          child: AnimatedContainer(
            duration: CwMotion.fast,
            height: widget.height,
            width: widget.expand ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(CwRadius.m + 2),
              boxShadow: shadow,
            ),
            alignment: Alignment.center,
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Round icon button used in top bars and over cards.
class CwCircleButton extends StatelessWidget {
  final CwIcons icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final Color? background;
  final Color? foreground;
  final double size;

  const CwCircleButton(
    this.icon, {
    super.key,
    required this.onPressed,
    required this.semanticLabel,
    this.background,
    this.foreground,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: background ?? c.surface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onPressed!();
                },
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child:
                  CwIcon(icon, size: CwIconSize.m, color: foreground ?? c.ink),
            ),
          ),
        ),
      ),
    );
  }
}
