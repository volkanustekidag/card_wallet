import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_service.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';

class CreditCardController extends GetxController {
  final CreditCardService _creditCardService = CreditCardService();

  var creditCards = <CreditCard>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Seed from HomeController so the route transition can render real
    // content on its first frame instead of waiting on Hive. The reload
    // happens after the first frame so the fade-in isn't fighting the
    // box read for UI thread time.
    if (Get.isRegistered<HomeController>()) {
      final home = Get.find<HomeController>();
      if (home.creditCards.isNotEmpty) {
        creditCards.assignAll(home.creditCards);
      }
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      loadCreditCards();
    });
  }

  Future<void> loadCreditCards() async {
    try {
      // Suppress the spinner when we already have seeded content; the
      // page should never blank back to a CircularProgressIndicator
      // during a quiet refresh.
      if (creditCards.isEmpty) {
        isLoading.value = true;
      }
      await _creditCardService.openBox();

      final result = await _creditCardService.getAllCreditCards();
      creditCards.value = result;
    } catch (e) {
      debugPrint('Error loading credit cards: $e');
      Get.context?.showErrorSnackBar(
          "failedToLoadCreditCards".tr(args: [e.toString()]));
      // Keep whatever was seeded — don't blank the screen on error.
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeCreditCard(CreditCard creditCard) async {
    try {
      await _creditCardService.removeToCreditCard(creditCard);
      creditCards.remove(creditCard);
      Get.context?.showSuccessSnackBar("creditCardDeletedSuccessfully".tr());
    } catch (e) {
      debugPrint('Error removing credit card: $e');
      Get.context?.showErrorSnackBar(
          "failedToDeleteCreditCard".tr(args: [e.toString()]));
    }
  }

  Future<void> addCreditCard(CreditCard creditCard) async {
    try {
      await _creditCardService.openBox();
      await _creditCardService.addToCreditCard(creditCard);
      await loadCreditCards();
      Get.context?.showSuccessSnackBar("creditCardAddedSuccessfully".tr());
    } catch (e) {
      debugPrint('Error adding credit card: $e');
      Get.context?.showErrorSnackBar(
          "failedToSaveCreditCard".tr(args: [e.toString()]));
    }
  }
}
