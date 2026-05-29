import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallet_app/core/utils/tag_index.dart';

/// Horizontal scrollable row of toggleable tag chips. Hides itself when
/// the underlying tag pool is empty so brand-new wallets don't see a
/// chrome-only row. Multi-select uses AND semantics — a card has to
/// carry every selected tag to pass.
class TagFilterChips extends StatelessWidget {
  final Iterable<String> tags;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final EdgeInsets padding;

  const TagFilterChips({
    Key? key,
    required this.tags,
    required this.selected,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ordered = sortedTags(tags);
    if (ordered.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: ordered.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final t = ordered[i];
            final isSelected = selected.contains(t);
            return _TagChip(
              label: t,
              selected: isSelected,
              isFavorite: t == kFavoriteTag,
              accent: colorScheme.primary,
              onTap: () {
                HapticFeedback.selectionClick();
                final next = {...selected};
                if (isSelected) {
                  next.remove(t);
                } else {
                  next.add(t);
                }
                onChanged(next);
              },
            );
          },
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isFavorite;
  final Color accent;
  final VoidCallback onTap;

  const _TagChip({
    required this.label,
    required this.selected,
    required this.isFavorite,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.16)
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? accent
                  : colorScheme.onSurface.withValues(alpha: 0.08),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isFavorite) ...[
                const Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: Color(0xFFFFB800),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                isFavorite ? 'Favorites' : label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? accent
                      : colorScheme.onSurface.withValues(alpha: 0.78),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 4),
                Icon(Icons.close_rounded, size: 13, color: accent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
