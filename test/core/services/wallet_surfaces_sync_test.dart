import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/services/wallet_surfaces_sync.dart';

LoyaltyCard _card(String id) => LoyaltyCard(
      id: id,
      name: 'Card $id',
      barcode: '1234567890',
      barcodeFormat: 'CODE_128',
      colorId: 0,
    );

void main() {
  late List<LoyaltyCard> boxCards;
  late StreamController<Object?> changes;
  late List<List<String>> widgetCalls;
  late List<List<String>> watchScheduled;
  late List<List<String>> watchPushed;
  late int widgetCleared;
  late WalletSurfacesSync sync;

  setUp(() {
    boxCards = [_card('a')];
    changes = StreamController<Object?>.broadcast();
    widgetCalls = [];
    watchScheduled = [];
    watchPushed = [];
    widgetCleared = 0;
    sync = WalletSurfacesSync(
      loadCards: () async => List.of(boxCards),
      watchChanges: () async => changes.stream,
      reconcileWidget: (cards) async =>
          widgetCalls.add(cards.map((c) => c.id).toList()),
      clearWidget: () async => widgetCleared++,
      scheduleWatchSync: (cards) =>
          watchScheduled.add(cards.map((c) => c.id).toList()),
      pushWatchNow: (cards) async =>
          watchPushed.add(cards.map((c) => c.id).toList()),
      debounce: const Duration(milliseconds: 20),
    );
  });

  tearDown(() async {
    await sync.stop();
    await changes.close();
  });

  test('start syncs widget and watch immediately', () async {
    await sync.start();
    expect(widgetCalls, [
      ['a'],
    ]);
    expect(watchScheduled, [
      ['a'],
    ]);
  });

  test('box changes are debounced into one sync', () async {
    await sync.start();
    boxCards = [_card('a'), _card('b')];
    changes
      ..add(null)
      ..add(null)
      ..add(null);
    await Future<void>.delayed(const Duration(milliseconds: 60));

    expect(widgetCalls.length, 2);
    expect(widgetCalls.last, ['a', 'b']);
    expect(watchScheduled.last, ['a', 'b']);
  });

  test('clearAll empties widget and watch right away', () async {
    await sync.start();
    await sync.clearAll();
    expect(widgetCleared, 1);
    expect(watchPushed, [<String>[]]);
  });

  test('a failing load does not throw', () async {
    final failing = WalletSurfacesSync(
      loadCards: () async => throw StateError('box closed'),
      watchChanges: () async => const Stream.empty(),
      reconcileWidget: (_) async {},
      clearWidget: () async {},
      scheduleWatchSync: (_) {},
      pushWatchNow: (_) async {},
    );
    await expectLater(failing.start(), completes);
    await failing.stop();
  });
}
