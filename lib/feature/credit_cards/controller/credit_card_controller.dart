import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_service.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';

class CreditCardController extends GetxController {
  final CreditCardService _creditCardService = CreditCardService();

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

      // Service'den güvenli şekilde kartları al
      final result = await _creditCardService.getAllCreditCards();
      creditCards.value = result;
    } catch (e) {
      print('Error loading credit cards: $e');
      // Detaylı hata mesajı göster
      Get.context?.showErrorSnackBar(
          "failedToLoadCreditCards".tr(args: [e.toString()]));
      creditCards.value = []; // Hata durumunda boş liste
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
      print('Error removing credit card: $e');
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
      print('Error adding credit card: $e');
      Get.context?.showErrorSnackBar(
          "failedToSaveCreditCard".tr(args: [e.toString()]));
    }
  }
}
