import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Sticky search + sort bar shared by all three card list pages.
/// Sort options correspond to [CardSortOption]; [options] defaults to all
/// but [CardSortOption.mostUsed], which only loyalty cards track.
class CardSearchBar extends StatelessWidget {
  final String query;
  final CardSortOption sort;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<CardSortOption> onSortChanged;
  final List<CardSortOption> options;

  const CardSearchBar({
    Key? key,
    required this.query,
    required this.sort,
    required this.onQueryChanged,
    required this.onSortChanged,
    this.options = CardSortOption.common,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: onQueryChanged,
              decoration: InputDecoration(
                hintText: 'searchCardsHint'.tr(),
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                filled: true,
                fillColor:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<CardSortOption>(
            initialValue: sort,
            tooltip: 'sortBy'.tr(),
            icon: Icon(Icons.sort_rounded, color: colorScheme.onSurface),
            onSelected: onSortChanged,
            itemBuilder: (_) => [
              for (final option in options)
                PopupMenuItem(
                  value: option,
                  child: Row(
                    children: [
                      Icon(
                        option == sort
                            ? Icons.check_rounded
                            : Icons.remove,
                        size: 16,
                        color: option == sort
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 8),
                      Text(option.label.tr()),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

enum CardSortOption {
  /// Favourites → most used → newest (loyalty cards only).
  mostUsed('sortMostUsed'),
  newest('sortNewest'),
  oldest('sortOldest'),
  nameAsc('sortNameAsc'),
  nameDesc('sortNameDesc'),
  bank('sortByBank');

  final String label;
  const CardSortOption(this.label);

  static const List<CardSortOption> common = [
    newest,
    oldest,
    nameAsc,
    nameDesc,
    bank,
  ];
}
