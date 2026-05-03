import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/data/local_services/card_services/loyalty_card/loyalty_card_service.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';

class LoyaltyCardController extends GetxController {
  final LoyaltyCardService _service = LoyaltyCardService();

  final loyaltyCards = <LoyaltyCard>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Seed from HomeController if it's already loaded the cards. This
    // makes the page render its real content on the very first frame
    // instead of flashing the spinner — without this, the route
    // transition was racing the Hive read and the user perceived a
    // multi-second hang before the page popped in.
    _seedFromHomeController();
    // Defer the (re)load to after the first frame so the route
    // transition starts smoothly. Hive deserialization is fast but it
    // still costs a few ms on the UI thread; doing it on the same tick
    // we're trying to animate in stutters the fade.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      loadLoyaltyCards();
    });
  }

  void _seedFromHomeController() {
    if (!Get.isRegistered<HomeController>()) return;
    final home = Get.find<HomeController>();
    if (home.loyaltyCards.isNotEmpty) {
      loyaltyCards.assignAll(home.loyaltyCards);
    }
  }

  Future<void> loadLoyaltyCards() async {
    try {
      // Only show the spinner if we don't already have data on screen.
      // Re-entry refreshes (after add/edit/delete) shouldn't blank the
      // list and replace it with a CircularProgressIndicator.
      if (loyaltyCards.isEmpty) {
        isLoading.value = true;
      }
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
