import 'package:get/get.dart';
import 'package:wallet_app/core/data/local_services/card_services/credit_card_service.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';

class CreditCardController extends GetxController {
  final CreditCardService _creditCardService;

  CreditCardController(this._creditCardService);

  var creditCards = <CreditCard>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadCreditCards();
  }

  Future<void> loadCreditCards() async {
    try {
      isLoading.value = true;
      await _creditCardService.openBox();
      final result = await _creditCardService.getAllCreditCards();
      creditCards.value = result;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load credit cards');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeCreditCard(CreditCard creditCard) async {
    try {
      await _creditCardService.removeToCreditCard(creditCard);
      await loadCreditCards();
      Get.snackbar('Success', 'Credit card deleted successfully',
          backgroundColor: Get.theme.primaryColor);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete credit card');
    }
  }

  Future<void> addCreditCard(CreditCard creditCard) async {
    try {
      await _creditCardService.openBox();
      await _creditCardService.addToCreditCard(creditCard);
      await loadCreditCards();
      Get.snackbar('Success', 'Credit card added successfully',
          backgroundColor: Get.theme.primaryColor);
    } catch (e) {
      Get.snackbar('Error', 'Failed to add credit card');
    }
  }
}
