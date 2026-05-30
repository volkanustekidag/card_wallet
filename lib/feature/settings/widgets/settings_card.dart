import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallet_app/core/widgets/lifted_surface.dart';

class SettingsCard extends StatefulWidget {
  final IconData iconData;
  final String title;
  final String? subtitle;
  final Color? subtitleColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;
  final Color? color;

  /// When true, show a small "Premium" pill next to the title so the locked
  /// state is visible without tapping. Tap routing is left to the caller.
  final bool premiumLocked;

  const SettingsCard({
    Key? key,
    required this.iconData,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
    this.color,
    this.premiumLocked = false,
  }) : super(key: key);

  @override
  State<SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<SettingsCard> {
  bool _down = false;

  void _setDown(bool down) {
    if (_down == down) return;
    setState(() => _down = down);
  }

  void _onTap() {
    if (widget.onTap == null) return;
    HapticFeedback.selectionClick();
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedScale(
      scale: _down ? 0.985 : 1,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: LiftedSurface(
        margin: const EdgeInsets.only(bottom: 12),
        color: widget.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap == null ? null : _onTap,
            onHighlightChanged: widget.onTap == null ? null : _setDown,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.isDestructive
                          ? colorScheme.error.withValues(alpha: 0.1)
                          : colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.iconData,
                      color: widget.isDestructive
                          ? colorScheme.error
                          : colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: widget.isDestructive
                                      ? colorScheme.error
                                      : colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (widget.premiumLocked) ...[
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: widget.subtitleColor ??
                                  colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.trailing != null) widget.trailing!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

