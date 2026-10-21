import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/utils/loyalty_usage.dart';
import 'package:wallet_app/core/utils/tag_index.dart';
import 'package:wallet_app/feature/home/widgets/sections/recent_cards_list.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';

LoyaltyCard _card(
  String id, {
  int? uses,
  DateTime? lastUsed,
  DateTime? created,
  bool favorite = false,
}) =>
    LoyaltyCard(
      id: id,
      name: id,
      barcode: '1',
      barcodeFormat: 'EAN_13',
      colorId: 0,
      createdAt: created ?? DateTime(2026, 1, 1),
      tags: favorite ? [kFavoriteTag] : null,
      useCount: uses,
      lastUsedAt: lastUsed,
    );

void main() {
  test('markLoyaltyUsed counts from null and stamps the time', () {
    final card = _card('a');
    final t1 = DateTime(2026, 10, 1, 9);
    markLoyaltyUsed(card, t1);
    expect(card.useCount, 1);
    expect(card.lastUsedAt, t1);
    final t2 = DateTime(2026, 10, 2, 9);
    markLoyaltyUsed(card, t2);
    expect(card.useCount, 2);
    expect(card.lastUsedAt, t2);
  });

  test('favourites → useCount → lastUsedAt → newest', () {
    final cards = [
      _card('new-unused', created: DateTime(2026, 9, 1)),
      _card('old-unused', created: DateTime(2025, 1, 1)),
      _card('used-3-old', uses: 3, lastUsed: DateTime(2026, 1, 1)),
      _card('used-3-recent', uses: 3, lastUsed: DateTime(2026, 10, 1)),
      _card('used-9', uses: 9, lastUsed: DateTime(2025, 6, 1)),
      _card('fav-unused', favorite: true),
      _card('fav-used', favorite: true, uses: 1, lastUsed: DateTime(2026, 2, 1)),
    ];
    expect(sortLoyaltyByUsage(cards).map((c) => c.id), [
      'fav-used',
      'fav-unused',
      'used-9',
      'used-3-recent',
      'used-3-old',
      'new-unused',
      'old-unused',
    ]);
  });

  test('cards from before 2.2 (no usage fields) keep newest-first order', () {
    final cards = [
      _card('2024', created: DateTime(2024)),
      _card('2026', created: DateTime(2026)),
      _card('2025', created: DateTime(2025)),
    ];
    expect(sortLoyaltyByUsage(cards).map((c) => c.id), ['2026', '2025', '2024']);
  });

  test('home Loyalty filter uses the usage order; All stays as given', () {
    final items = [
      WalletItem.loyalty(_card('newest', created: DateTime(2026, 9, 1))),
      WalletItem.loyalty(_card('most-used', uses: 5)),
      WalletItem.loyalty(_card('fav', favorite: true)),
    ];
    expect(
      RecentCardsList.visibleItems(items, HomeFilter.loyalty, 5)
          .map((i) => i.id),
      ['fav', 'most-used', 'newest'],
    );
    expect(
      RecentCardsList.visibleItems(items, HomeFilter.all, 2).map((i) => i.id),
      ['newest', 'most-used'],
    );
  });
}
