import 'package:get/get.dart';
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/iban_card_service.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';

class HomeController extends GetxController {
  final CreditCardService _creditCardService = CreditCardService();
  final IbanCardService _ibanCardService = IbanCardService();

  var creditCards = <CreditCard>[].obs;
  var ibanCards = <IbanCard>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadHomeContent();
  }

  Future<void> loadHomeContent() async {
    try {
      isLoading.value = true;
      await _creditCardService.openBox();
      await _ibanCardService.openBox();

      final creditCardList = await _creditCardService.getAllCreditCards();
      final ibanCardList = await _ibanCardService.getAllIbanCards();

      creditCards.value = creditCardList;
      ibanCards.value = ibanCardList;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load home content');
    } finally {
      isLoading.value = false;
    }
  }

  void refreshData() {
    loadHomeContent();
  }
}
