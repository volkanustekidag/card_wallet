import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/data/local_services/card_services/loyalty_card/loyalty_card_service.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';

class LoyaltyCardController extends GetxController {
  final LoyaltyCardService _service = LoyaltyCardService();

  final loyaltyCards = <LoyaltyCard>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadLoyaltyCards();
  }

  Future<void> loadLoyaltyCards() async {
    try {
      isLoading.value = true;
      await _service.openBox();
      loyaltyCards.value = await _service.getAllLoyaltyCards();
      _syncPremiumCount();
    } catch (e) {
      debugPrint('Error loading loyalty cards: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeLoyaltyCard(LoyaltyCard card) async {
    try {
      await _service.removeLoyaltyCard(card);
      loyaltyCards.removeWhere((c) => c.id == card.id);
      _syncPremiumCount();
    } catch (e) {
      debugPrint('Error removing loyalty card: $e');
    }
  }

  void _syncPremiumCount() {
    if (Get.isRegistered<PremiumController>()) {
      final premium = Get.find<PremiumController>();
      premium.setCardCounts(
        creditCount: premium.creditCardCount,
        ibanCount: premium.ibanCardCount,
        loyaltyCount: loyaltyCards.length,
      );
    }
  }
}
