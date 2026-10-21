import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/services/watch_sync_service.dart';

LoyaltyCard _card(String id, {int? uses, DateTime? lastUsed}) => LoyaltyCard(
      id: id,
      name: id,
      barcode: '1',
      barcodeFormat: 'EAN_13',
      colorId: 0,
      createdAt: DateTime(2026),
      useCount: uses,
      lastUsedAt: lastUsed,
    );

void main() {
  test('watch payload carries usage and is in usage order', () {
    final json = jsonDecode(WatchSyncService.encodePayload([
      _card('never'),
      _card('often', uses: 4, lastUsed: DateTime.utc(2026, 10, 20, 9)),
    ])) as Map<String, dynamic>;

    expect(json['version'], 1);
    final cards = (json['cards'] as List).cast<Map<String, dynamic>>();
    expect(cards.map((c) => c['id']), ['often', 'never']);
    expect(cards.first['useCount'], 4);
    expect(cards.first['lastUsedAt'], '2026-10-20T09:00:00.000Z');
    expect(cards.last['useCount'], 0);
    expect(cards.last['lastUsedAt'], isNull);
    // The original keys the watch decodes are still there.
    expect(cards.first.keys, containsAll(
      ['id', 'name', 'brand', 'barcode', 'format', 'color1', 'color2'],
    ));
  });
}
