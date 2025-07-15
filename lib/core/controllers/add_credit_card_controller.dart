import 'package:get/get.dart';
import 'package:wallet_app/core/controllers/credit_card_controller.dart';
import 'package:wallet_app/data/local_services/card_services/credit_card_service.dart';
import 'package:wallet_app/domain/models/credit_card_model/credit_card.dart';

class AddCreditCardController extends GetxController {
  final CreditCardService _creditCardService;

  AddCreditCardController(this._creditCardService);

  var currentCard = CreditCard(1, "", "", "", "", "", 1).obs;
  var isLoading = false.obs;

  void updateCardField(String fieldName, dynamic value) {
    final card = currentCard.value;

    switch (fieldName) {
      case "cardColorId":
        card.cardColorId = value as int;
        break;
      case "bankName":
        card.bankName = value as String;
        break;
      case "creditCardNumber":
        card.creditCardNumber = value as String;
        break;
      case "cardHolder":
        card.cardHolder = value as String;
        break;
      case "expirationDate":
        card.expirationDate = value as String;
        break;
      case "cvc2":
        card.cvc2 = value as String;
        break;
    }

    currentCard.refresh(); // Trigger UI update
  }

  Future<void> saveCard() async {
    try {
      isLoading.value = true;
      await _creditCardService.openBox();
      await _creditCardService.addToCreditCard(currentCard.value);

      // Reset form
      currentCard.value = CreditCard(1, "", "", "", "", "", 1);

      Get.back();
      Get.snackbar('Success', 'Credit card added successfully',
          backgroundColor: Get.theme.primaryColor);

      // Update credit cards list
      final creditCardController = Get.find<CreditCardController>();
      creditCardController.loadCreditCards();
    } catch (e) {
      Get.snackbar('Error', 'Failed to save credit card');
    } finally {
      isLoading.value = false;
    }
  }

  void resetCard() {
    currentCard.value = CreditCard(1, "", "", "", "", "", 1);
  }
}
