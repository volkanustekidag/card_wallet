import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modern wallet-style footer for bottom sheets: a row of equal-width
/// icon-over-label tiles. Replaces dated ListTile menus on share/edit/delete
/// surfaces.
class SheetActionBar extends StatelessWidget {
  final List<SheetAction> actions;

  /// When true, tiles render in a translucent style suitable for sitting on
  /// top of a colored gradient (loyalty/credit hero backdrops).
  final bool onDark;

  const SheetActionBar({
    Key? key,
    required this.actions,
    this.onDark = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: SheetActionButton(action: actions[i], onDark: onDark),
          ),
        ],
      ],
    );
  }
}

class SheetAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  const SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });
}

class SheetActionButton extends StatelessWidget {
  final SheetAction action;
  final bool onDark;
  const SheetActionButton({
    Key? key,
    required this.action,
    this.onDark = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = onDark
        ? Colors.white.withValues(alpha: 0.18)
        : (action.destructive
            ? colorScheme.error.withValues(alpha: 0.1)
            : colorScheme.surfaceContainerHighest);
    final fg = onDark
        ? Colors.white
        : (action.destructive
            ? colorScheme.error
            : colorScheme.onSurface.withValues(alpha: 0.85));
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticFeedback.lightImpact();
          action.onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: onDark
                ? Border.all(color: Colors.white.withValues(alpha: 0.28))
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(action.icon, size: 20, color: fg),
              const SizedBox(height: 4),
              Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
