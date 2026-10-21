import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/utils/card_sorting.dart';
import 'package:wallet_app/core/utils/tag_index.dart';

/// Marks one barcode display on [card]: bumps [LoyaltyCard.useCount] and
/// stamps [LoyaltyCard.lastUsedAt]. Caller persists.
void markLoyaltyUsed(LoyaltyCard card, DateTime now) {
  card.useCount = (card.useCount ?? 0) + 1;
  card.lastUsedAt = now;
}

/// Default loyalty order: favourites first, then most used (useCount, ties
/// broken by most recent lastUsedAt), then newest. Cards never used sit
/// after used ones and keep the newest-first order among themselves.
int compareLoyaltyByUsage(LoyaltyCard a, LoyaltyCard b) {
  final favA = a.tags?.contains(kFavoriteTag) ?? false;
  final favB = b.tags?.contains(kFavoriteTag) ?? false;
  if (favA != favB) return favA ? -1 : 1;

  final countCmp = (b.useCount ?? 0).compareTo(a.useCount ?? 0);
  if (countCmp != 0) return countCmp;

  final lastA = a.lastUsedAt;
  final lastB = b.lastUsedAt;
  if (lastA != null || lastB != null) {
    if (lastA == null) return 1;
    if (lastB == null) return -1;
    final lastCmp = lastB.compareTo(lastA);
    if (lastCmp != 0) return lastCmp;
  }

  return compareNewestFirst(
    aCreatedAt: a.createdAt,
    aId: a.id,
    bCreatedAt: b.createdAt,
    bId: b.id,
  );
}

/// Copy of [cards] in [compareLoyaltyByUsage] order.
List<LoyaltyCard> sortLoyaltyByUsage(Iterable<LoyaltyCard> cards) =>
    cards.toList()..sort(compareLoyaltyByUsage);
