import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';

/// The 2.1 adapter: same typeId, fields 0-10 only.
class _LegacyLoyaltyAdapter extends TypeAdapter<LoyaltyCard> {
  @override
  final int typeId = 4;

  @override
  LoyaltyCard read(BinaryReader reader) => throw UnimplementedError();

  @override
  void write(BinaryWriter writer, LoyaltyCard obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.brand)
      ..writeByte(3)
      ..write(obj.barcode)
      ..writeByte(4)
      ..write(obj.barcodeFormat)
      ..writeByte(5)
      ..write(obj.colorId)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.logoAsset)
      ..writeByte(9)
      ..write(obj.tags)
      ..writeByte(10)
      ..write(obj.website);
  }
}

LoyaltyCard _card({int? uses, DateTime? lastUsed}) => LoyaltyCard(
      id: 'l1',
      name: 'Migros',
      barcode: '123',
      barcodeFormat: 'EAN_13',
      colorId: 1,
      useCount: uses,
      lastUsedAt: lastUsed,
    );

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('loyalty_adapter_test');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('a card stored by 2.1 opens in 2.2 with no usage (no migration)',
      () async {
    Hive.registerAdapter(_LegacyLoyaltyAdapter(), override: true);
    final legacy = await Hive.openBox<LoyaltyCard>('loyalty');
    await legacy.add(_card());
    await legacy.close();

    Hive.registerAdapter(LoyaltyCardAdapter(), override: true);
    final box = await Hive.openBox<LoyaltyCard>('loyalty');
    final read = box.getAt(0)!;
    expect(read.name, 'Migros');
    expect(read.useCount, isNull);
    expect(read.lastUsedAt, isNull);
  });

  test('usage fields persist across reopen', () async {
    Hive.registerAdapter(LoyaltyCardAdapter(), override: true);
    final when = DateTime(2026, 10, 21, 12);
    var box = await Hive.openBox<LoyaltyCard>('loyalty');
    await box.add(_card(uses: 4, lastUsed: when));
    await box.close();

    box = await Hive.openBox<LoyaltyCard>('loyalty');
    expect(box.getAt(0)!.useCount, 4);
    expect(box.getAt(0)!.lastUsedAt, when);
  });
}
