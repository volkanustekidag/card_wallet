import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/utils/tag_index.dart';
import 'package:wallet_app/feature/add_loyalty_card/controller/add_loyalty_card_controller.dart';

void main() {
  test('editing a loyalty card keeps its tags (favorite included)', () {
    final created = DateTime(2025, 1, 2);
    final original = LoyaltyCard(
      id: 'card-1',
      name: 'Old name',
      barcode: '111',
      barcodeFormat: 'EAN_13',
      colorId: 1,
      createdAt: created,
      tags: [kFavoriteTag, 'groceries'],
      useCount: 12,
      lastUsedAt: DateTime(2026, 10, 1),
    );
    final draft = LoyaltyCard(
      id: 'card-1',
      name: 'New name',
      barcode: '222',
      barcodeFormat: 'CODE_128',
      colorId: 3,
      notes: 'note',
      tags: List<String>.from(original.tags!),
    );

    final saved = AddLoyaltyCardController.mergeEdit(original, draft);

    expect(saved.tags, [kFavoriteTag, 'groceries']);
    expect(saved.id, 'card-1');
    expect(saved.createdAt, created);
    expect(saved.name, 'New name');
    expect(saved.barcode, '222');
    expect(saved.barcodeFormat, 'CODE_128');
    expect(saved.colorId, 3);
    expect(saved.notes, 'note');
    // Editing must not reset the usage ordering.
    expect(saved.useCount, 12);
    expect(saved.lastUsedAt, DateTime(2026, 10, 1));
  });
}
