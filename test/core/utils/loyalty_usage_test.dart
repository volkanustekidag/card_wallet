import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/utils/loyalty_usage.dart';
import 'package:wallet_app/core/utils/tag_index.dart';
import 'package:wallet_app/feature/home/wallet_home.dart';
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

  test('home stack: favourites first, then the usage order', () {
    final items = [
      WalletItem.loyalty(_card('newest', created: DateTime(2026, 9, 1))),
      WalletItem.loyalty(_card('most-used', uses: 5)),
      WalletItem.loyalty(_card('fav', favorite: true)),
    ];
    expect(
      stackOrder(items, HomeFilter.loyalty).map((i) => i.id),
      ['fav', 'most-used', 'newest'],
    );
  });

  test('markLoyaltyUsed keeps a capped usage log', () {
    final card = _card('a');
    final start = DateTime(2026, 10, 1, 9);
    for (var i = 0; i < kUsageLogCap + 5; i++) {
      markLoyaltyUsed(card, start.add(Duration(days: i)));
    }
    expect(card.usageLog, hasLength(kUsageLogCap));
    expect(card.usageLog!.last,
        start.add(Duration(days: kUsageLogCap + 4)).millisecondsSinceEpoch);
  });

  test('Up Next prefers the card used around this time of day', () {
    final now = DateTime(2026, 10, 22, 8, 30);
    final morning = _card('coffee');
    final evening = _card('grocery');
    for (var d = 1; d <= 6; d++) {
      markLoyaltyUsed(morning, now.subtract(Duration(days: d)));
      markLoyaltyUsed(
          evening, now.subtract(Duration(days: d)).add(const Duration(hours: 10)));
    }
    expect(sortLoyaltyForNow([evening, morning], now).first.id, 'coffee');
    expect(
      sortLoyaltyForNow([morning, evening], now.add(const Duration(hours: 10)))
          .first
          .id,
      'grocery',
    );
  });

  test('Up Next: never-used cards score zero and keep their order', () {
    final now = DateTime(2026, 10, 22, 12);
    final a = _card('a', created: DateTime(2026, 2));
    final b = _card('b', created: DateTime(2026, 1));
    expect(upNextScore(a, now), 0);
    expect(sortLoyaltyForNow([b, a], now).map((c) => c.id), ['a', 'b']);
  });
}
