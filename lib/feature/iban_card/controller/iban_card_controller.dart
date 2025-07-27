import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/iban_card_service.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';

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
      Get.context?.showErrorSnackBar(
          '${'failedToLoadIbanCards'.tr()}: ${e.toString()}');
      ibanCards.value = []; // Hata durumunda boş liste
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeIbanCard(IbanCard ibanCard) async {
    try {
      await _ibanCardService.removeIbanCard(ibanCard);
      ibanCards.remove(ibanCard);
      Get.context?.showSuccessSnackBar('ibanCardDeletedSuccessfully'.tr());
    } catch (e) {
      print('Error removing IBAN card: $e');
      Get.context?.showErrorSnackBar(
          '${'failedToDeleteIbanCard'.tr()}: ${e.toString()}');
    }
  }

  Future<void> addIbanCard(IbanCard ibanCard) async {
    try {
      await _ibanCardService.openBox();
      await _ibanCardService.addIbanCard(ibanCard);
      await loadIbanCards();
      Get.context?.showSuccessSnackBar('ibanCardAddedSuccessfully'.tr());
    } catch (e) {
      print('Error adding IBAN card: $e');
      Get.context
          ?.showErrorSnackBar('${'failedToAddIbanCard'.tr()}: ${e.toString()}');
    }
  }
}
