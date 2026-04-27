import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/iban_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/loyalty_card/loyalty_card_service.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/utils/card_sorting.dart';

class HomeController extends GetxController {
  final CreditCardService _creditCardService = CreditCardService();
  final IbanCardService _ibanCardService = IbanCardService();
  final LoyaltyCardService _loyaltyCardService = LoyaltyCardService();

  var creditCards = <CreditCard>[].obs;
  var ibanCards = <IbanCard>[].obs;
  var loyaltyCards = <LoyaltyCard>[].obs;
  var isLoading = false.obs;
  final latestCreditCard = Rxn<CreditCard>();
  final latestIbanCard = Rxn<IbanCard>();
  final latestLoyaltyCard = Rxn<LoyaltyCard>();

  @override
  void onInit() {
    super.onInit();
    loadHomeContent();
  }

  Future<void> loadHomeContent() async {
    try {
      isLoading.value = true;
      await Future.wait([
        _creditCardService.openBox(),
        _ibanCardService.openBox(),
        _loyaltyCardService.openBox(),
      ]);

      final results = await Future.wait([
        _creditCardService.getAllCreditCards(),
        _ibanCardService.getAllIbanCards(),
        _loyaltyCardService.getAllLoyaltyCards(),
      ]);
      final creditCardList = results[0] as List<CreditCard>;
      final ibanCardList = results[1] as List<IbanCard>;
      final loyaltyCardList = results[2] as List<LoyaltyCard>;

      creditCards.value = creditCardList;
      ibanCards.value = ibanCardList;
      loyaltyCards.value = loyaltyCardList;

      latestCreditCard.value = _findLatestCreditCard(creditCardList);
      latestIbanCard.value = _findLatestIbanCard(ibanCardList);
      latestLoyaltyCard.value = _findLatestLoyaltyCard(loyaltyCardList);

      if (Get.isRegistered<PremiumController>()) {
        Get.find<PremiumController>().setCardCounts(
          creditCount: creditCardList.length,
          ibanCount: ibanCardList.length,
          loyaltyCount: loyaltyCardList.length,
        );
      }
    } catch (e) {
      debugPrint('Error loading home content: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void refreshData() {
    loadHomeContent();
  }

  CreditCard? _findLatestCreditCard(List<CreditCard> cards) {
    if (cards.isEmpty) return null;
    final sorted = [...cards]..sort((a, b) => compareNewestFirst(
          aCreatedAt: a.createdAt,
          aId: a.id,
          bCreatedAt: b.createdAt,
          bId: b.id,
        ));
    return sorted.first;
  }

  IbanCard? _findLatestIbanCard(List<IbanCard> cards) {
    if (cards.isEmpty) return null;
    final sorted = [...cards]..sort((a, b) => compareNewestFirst(
          aCreatedAt: a.createdAt,
          aId: a.id,
          bCreatedAt: b.createdAt,
          bId: b.id,
        ));
    return sorted.first;
  }

  LoyaltyCard? _findLatestLoyaltyCard(List<LoyaltyCard> cards) {
    if (cards.isEmpty) return null;
    final sorted = [...cards]..sort((a, b) => compareNewestFirst(
          aCreatedAt: a.createdAt,
          aId: a.id,
          bCreatedAt: b.createdAt,
          bId: b.id,
        ));
    return sorted.first;
  }
}
