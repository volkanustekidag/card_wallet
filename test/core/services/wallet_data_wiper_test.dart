import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/services/wallet_data_wiper.dart';

void main() {
  test('wipe cancels reminders before deleting, then clears surfaces',
      () async {
    final log = <String>[];
    final cards = <CreditCard>[];
    final wiper = WalletDataWiper(
      loadCreditCards: () async {
        log.add('load');
        return cards;
      },
      cancelReminders: (c) async {
        expect(c, same(cards));
        log.add('cancelReminders');
      },
      deleteBoxes: [
        () async => log.add('deleteCredit'),
        () async => log.add('deleteIban'),
        () async => log.add('deleteLoyalty'),
      ],
      clearSurfaces: () async => log.add('clearSurfaces'),
      resetPremiumCounters: () => log.add('resetCounters'),
    );

    await wiper.wipe();

    expect(log, [
      'load',
      'cancelReminders',
      'deleteCredit',
      'deleteIban',
      'deleteLoyalty',
      'clearSurfaces',
      'resetCounters',
    ]);
  });
}
