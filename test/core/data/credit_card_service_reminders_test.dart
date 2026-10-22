import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_service.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/services/card_reminder_service.dart';

/// Mirrors the field failure: flutter_local_notifications rejects the
/// stripped small icon, so every reminder call throws.
class _ThrowingReminders extends Fake implements CardReminderService {
  int scheduleCalls = 0;
  int cancelCalls = 0;

  @override
  Future<void> scheduleForCard(
    CreditCard card, {
    bool promptForPermissions = true,
  }) async {
    scheduleCalls++;
    throw PlatformException(
      code: 'invalid_icon',
      message: 'The resource ic_stat_card_wallet could not be found.',
    );
  }

  @override
  Future<void> cancelForCard(CreditCard card) async {
    cancelCalls++;
    throw PlatformException(code: 'invalid_icon');
  }
}

CreditCard _card({String id = 'c1', String bank = 'Test Bank'}) => CreditCard(
      id: id,
      bankName: bank,
      creditCardNumber: '4111111111111111',
      cardHolder: 'A B',
      expirationDate: '12/30',
      cardColorId: 1,
      paymentReminderEnabled: true,
      paymentDueDay: 15,
    );

void main() {
  late Directory dir;
  late Box<CreditCard> box;
  late _ThrowingReminders reminders;
  late CreditCardService service;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('credit_card_service_test');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(CreditCardAdapter());
    box = await Hive.openBox<CreditCard>('credit_cards_test');
    reminders = _ThrowingReminders();
    service = CreditCardService.withBox(box, reminders: reminders);
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('add succeeds and stores the card when scheduleForCard throws',
      () async {
    await expectLater(service.addToCreditCard(_card()), completes);

    expect(reminders.scheduleCalls, 1);
    final cards = await service.getAllCreditCards();
    expect(cards, hasLength(1));
    expect(cards.single.id, 'c1');
  });

  test('update succeeds and stores the change when reminders throw', () async {
    final original = _card();
    await service.addToCreditCard(original);

    await expectLater(
      service.updateCreditCard(original, _card(bank: 'Renamed Bank')),
      completes,
    );

    expect(reminders.cancelCalls, 1);
    expect(reminders.scheduleCalls, 2);
    final cards = await service.getAllCreditCards();
    expect(cards, hasLength(1));
    expect(cards.single.bankName, 'Renamed Bank');
  });

  test('remove succeeds when cancelForCard throws', () async {
    final card = _card();
    await service.addToCreditCard(card);

    await expectLater(service.removeToCreditCard(card), completes);

    expect(await service.getAllCreditCards(), isEmpty);
  });

  test('guarded swallows the error instead of rethrowing', () async {
    var ran = false;
    await expectLater(
      CardReminderService.guarded('test', () async {
        ran = true;
        throw StateError('boom');
      }),
      completes,
    );
    expect(ran, isTrue);
  });
}
