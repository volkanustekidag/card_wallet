import 'package:get/get.dart';
import 'package:wallet_app/core/controllers/iban_card_controller.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card_service.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';

class AddIbanCardController extends GetxController {
  final IbanCardService _ibanCardService;

  AddIbanCardController(this._ibanCardService);

  var currentCard = IbanCard("", "", "", "", 1).obs;
  var isLoading = false.obs;

  void updateCardField(String fieldName, String value) {
    final card = currentCard.value;

    switch (fieldName) {
      case "cardHolder":
        card.cardHolder = value;
        break;
      case "iban":
        card.iban = value;
        break;
      case "swiftCode":
        card.swiftCode = value;
        break;
      case "bankName":
        card.bankName = value;
        break;
    }

    currentCard.refresh(); // Trigger UI update
  }

  Future<void> saveCard() async {
    try {
      isLoading.value = true;
      await _ibanCardService.openBox();
      await _ibanCardService.addIbanCard(currentCard.value);

      // Reset form
      currentCard.value = IbanCard("", "", "", "", 1);

      Get.back();
      Get.snackbar('Success', 'IBAN card added successfully',
          backgroundColor: Get.theme.primaryColor);

      // Update IBAN cards list
      final ibanCardController = Get.find<IbanCardController>();
      ibanCardController.loadIbanCards();
    } catch (e) {
      Get.snackbar('Error', 'Failed to save IBAN card');
    } finally {
      isLoading.value = false;
    }
  }

  void resetCard() {
    currentCard.value = IbanCard("", "", "", "", 1);
  }
}
