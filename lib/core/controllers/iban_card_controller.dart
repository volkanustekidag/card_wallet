import 'package:get/get.dart';
import 'package:wallet_app/data/local_services/card_services/iban_card_service.dart';
import 'package:wallet_app/domain/models/iban_card_model/iban_card.dart';

class IbanCardController extends GetxController {
  final IbanCardService _ibanCardService;
  
  IbanCardController(this._ibanCardService);

  var ibanCards = <IbanCard>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadIbanCards();
  }

  Future<void> loadIbanCards() async {
    try {
      isLoading.value = true;
      await _ibanCardService.openBox();
      final result = await _ibanCardService.getAllIbanCards();
      ibanCards.value = result;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load IBAN cards');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeIbanCard(IbanCard ibanCard) async {
    try {
      await _ibanCardService.removeIbanCard(ibanCard);
      await loadIbanCards();
      Get.snackbar('Success', 'IBAN card deleted successfully',
                   backgroundColor: Get.theme.primaryColor);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete IBAN card');
    }
  }

  Future<void> addIbanCard(IbanCard ibanCard) async {
    try {
      await _ibanCardService.openBox();
      await _ibanCardService.addIbanCard(ibanCard);
      await loadIbanCards();
      Get.snackbar('Success', 'IBAN card added successfully',
                   backgroundColor: Get.theme.primaryColor);
    } catch (e) {
      Get.snackbar('Error', 'Failed to add IBAN card');
    }
  }
}