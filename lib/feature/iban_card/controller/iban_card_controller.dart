import 'package:get/get.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/iban_card_service.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';

class IbanCardController extends GetxController {
  final IbanCardService _ibanCardService = IbanCardService();

  IbanCardController();

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
      print('Error loading IBAN cards: $e');
      Get.snackbar('Error', 'Failed to load IBAN cards: ${e.toString()}');
      ibanCards.value = []; // Hata durumunda boş liste
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeIbanCard(IbanCard ibanCard) async {
    try {
      await _ibanCardService.removeIbanCard(ibanCard);
      ibanCards.remove(ibanCard);
      Get.snackbar('Success', 'IBAN card deleted successfully',
          backgroundColor: Get.theme.primaryColor);
    } catch (e) {
      print('Error removing IBAN card: $e');
      Get.snackbar('Error', 'Failed to delete IBAN card: ${e.toString()}');
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
      print('Error adding IBAN card: $e');
      Get.snackbar('Error', 'Failed to add IBAN card: ${e.toString()}');
    }
  }
}
