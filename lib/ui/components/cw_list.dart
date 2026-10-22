import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

/// Section title above a [CwGroup] ("SECURITY", "DATA", …).
class CwSectionHeader extends StatelessWidget {
  final String text;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const CwSectionHeader(
    this.text, {
    super.key,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(32, 22, 32, 8),
  });

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: CwType.overline.copyWith(color: c.mute),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Inset grouped list container (rounded surface with hairline dividers).
class CwGroup extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  const CwGroup({
    super.key,
    required this.children,
    this.margin = const EdgeInsets.symmetric(horizontal: CwSpace.gutter),
  });

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final visible = children.where((w) => w is! SizedBox).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(CwRadius.m),
        boxShadow: CwElevation.e1(context),
      ),
      clipBehavior: Clip.antiAlias,
      // min: inside a bottom sheet the group must size to its rows, not
      // stretch to the sheet's full height.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.only(left: 58),
                child: Divider(height: 1, thickness: 1, color: c.line),
              ),
            visible[i],
          ],
        ],
      ),
    );
  }
}

/// Coloured rounded square with a white icon — the leading element of
/// settings-style rows.
class CwIconTile extends StatelessWidget {
  final CwIcons icon;
  final Color color;
  final double size;
  final Color? iconColor;

  const CwIconTile(
    this.icon, {
    super.key,
    required this.color,
    this.size = 30,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size * 0.27),
        ),
        alignment: Alignment.center,
        // Tiles tinted with ink flip to a light colour in dark mode; keep the
        // glyph readable on any fill.
        child: CwIcon(icon,
            size: size * 0.6,
            color: iconColor ??
                (color.computeLuminance() > 0.6
                    ? const Color(0xFF0E0F12)
                    : Colors.white)),
      );
}

/// One row inside a [CwGroup].
class CwRow extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Color? subtitleColor;
  final Widget? trailing;
  final String? value;
  final bool chevron;
  final VoidCallback? onTap;

  const CwRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.subtitleColor,
    this.trailing,
    this.value,
    this.chevron = false,
    this.onTap,
  });

  /// A row whose trailing widget is a [CwSwitch] toggles it when tapped
  /// anywhere (unless it has its own [onTap]).
  VoidCallback? get _effectiveTap {
    if (onTap != null) return onTap;
    final t = trailing;
    if (t is CwSwitch && t.onChanged != null) {
      return () => t.onChanged!(!t.value);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _effectiveTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                _effectiveTap!();
              },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 14)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: CwType.body.copyWith(
                          color: titleColor ?? c.ink,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: CwType.footnote
                              .copyWith(color: subtitleColor ?? c.mute),
                        ),
                      ],
                    ],
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(width: 8),
                  Text(value!, style: CwType.callout.copyWith(color: c.mute)),
                ],
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
                if (chevron) ...[
                  const SizedBox(width: 6),
                  CwIcon(CwIcons.chevronRight,
                      size: CwIconSize.s, color: c.mute),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Platform-native switch: Cupertino on iOS/macOS, Material 3 elsewhere.
class CwSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const CwSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final platform = Theme.of(context).platform;
    final isApple =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    if (isApple) {
      return CupertinoSwitch(
        value: value,
        activeTrackColor: c.ok,
        onChanged: onChanged == null
            ? null
            : (v) {
                HapticFeedback.selectionClick();
                onChanged!(v);
              },
      );
    }
    // Material 3 switch, coloured from our palette so it reads on both
    // light and night surfaces.
    return Switch(
      value: value,
      activeTrackColor: c.ok,
      activeThumbColor: Colors.white,
      inactiveTrackColor: c.surface2,
      inactiveThumbColor: c.mute,
      trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.ok : c.mute),
      onChanged: onChanged == null
          ? null
          : (v) {
              HapticFeedback.selectionClick();
              onChanged!(v);
            },
    );
  }
}
