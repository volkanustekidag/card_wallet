import 'package:get/get.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/iban_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/loyalty_card/loyalty_card_service.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/services/card_reminder_service.dart';
import 'package:wallet_app/core/services/wallet_surfaces_sync.dart';

/// "Delete all data": removes every card and everything derived from them —
/// scheduled reminders, the widget / quick tile snapshot, the Watch list and
/// the premium card counters. The caller handles confirmation + PIN.
class WalletDataWiper {
  WalletDataWiper({
    Future<List<CreditCard>> Function()? loadCreditCards,
    Future<void> Function(List<CreditCard> cards)? cancelReminders,
    List<Future<void> Function()>? deleteBoxes,
    Future<void> Function()? clearSurfaces,
    void Function()? resetPremiumCounters,
  })  : _loadCreditCards = loadCreditCards ?? _defaultLoadCreditCards,
        _cancelReminders =
            cancelReminders ?? CardReminderService().cancelAllForCards,
        _deleteBoxes = deleteBoxes ??
            [
              CreditCardService().deleteAllData,
              IbanCardService().deleteAllData,
              LoyaltyCardService().deleteAllData,
            ],
        _clearSurfaces =
            clearSurfaces ?? WalletSurfacesSync.instance.clearAll,
        _resetPremiumCounters =
            resetPremiumCounters ?? _defaultResetPremiumCounters;

  final Future<List<CreditCard>> Function() _loadCreditCards;
  final Future<void> Function(List<CreditCard> cards) _cancelReminders;
  final List<Future<void> Function()> _deleteBoxes;
  final Future<void> Function() _clearSurfaces;
  final void Function() _resetPremiumCounters;

  static Future<List<CreditCard>> _defaultLoadCreditCards() async {
    final service = CreditCardService();
    await service.openBox();
    return service.getAllCreditCards();
  }

  static void _defaultResetPremiumCounters() {
    if (!Get.isRegistered<PremiumController>()) return;
    Get.find<PremiumController>()
        .setCardCounts(creditCount: 0, ibanCount: 0, loyaltyCount: 0);
  }

  Future<void> wipe() async {
    // Reminder ids derive from the card, so cancel before the cards go.
    final creditCards = await _loadCreditCards();
    await _cancelReminders(creditCards);
    for (final delete in _deleteBoxes) {
      await delete();
    }
    await _clearSurfaces();
    _resetPremiumCounters();
  }
}
