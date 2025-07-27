import 'package:get/get.dart';
import 'package:wallet_app/feature/iban_card/controller/iban_card_controller.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/iban_card_service.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';

class AddIbanCardController extends GetxController {
  final IbanCardService _ibanCardService = IbanCardService();

  var currentCard = IbanCard(
    id: "",
    cardHolder: "",
    iban: "",
    swiftCode: "",
    bankName: "",
  ).obs;
  var isLoading = false.obs;
  var isEditMode = false.obs;
  IbanCard? _originalCard;

  // Benzersiz string ID oluştur
  String _generateNewId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (1000 + (999 * (DateTime.now().microsecond / 1000000)).round())
            .toString();
  }

  // Edit modu için başlatma
  void initializeForEdit(IbanCard card) {
    _originalCard = card;

    // Mevcut kartın verilerini kopyala (ID dahil - int olsa bile)
    currentCard.value = IbanCard(
      id: card.id, // Orijinal ID'yi koru (int veya string)
      cardHolder: card.cardHolder,
      iban: card.iban,
      swiftCode: card.swiftCode,
      bankName: card.bankName,
    );
    isEditMode.value = true;

    // Trigger refresh
    currentCard.refresh();

    print(
        'Edit mode initialized for IBAN card: ${card.cardHolder} - ${card.iban}');
  }

  // Yeni kart oluşturma modu için başlatma
  void initializeForCreate() {
    _originalCard = null;
    currentCard.value = IbanCard(
      id: _generateNewId(),
      cardHolder: "",
      iban: "",
      swiftCode: "",
      bankName: "",
    );
    isEditMode.value = false;

    // Trigger refresh
    currentCard.refresh();

    print('Create mode initialized for IBAN card');
  }

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

      // Premium kontrolü sadece yeni kart eklerken
      if (!isEditMode.value) {
        final ibanCardController = Get.put(IbanCardController());
        final premiumController = Get.find<PremiumController>();

        final currentCount = ibanCardController.ibanCards.length;
        if (!premiumController.canAddMoreIbanCards(currentCount)) {
          // Direkt premium sayfasına yönlendir
          Get.toNamed('/premium');
          return;
        }
      }

      if (isEditMode.value && _originalCard != null) {
        // Güncelleme işlemi - orijinal ID'yi koru
        final updatedCard = IbanCard(
          id: _originalCard!.id, // Orijinal ID'yi koru
          cardHolder: currentCard.value.cardHolder,
          iban: currentCard.value.iban,
          swiftCode: currentCard.value.swiftCode,
          bankName: currentCard.value.bankName,
        );

        await _ibanCardService.updateIbanCard(_originalCard!, updatedCard);
        Get.back();
        Get.context?.showSuccessSnackBar('IBAN card updated successfully');
      } else {
        // Yeni kart ekleme işlemi - yeni string ID
        final newCard = IbanCard(
          id: _generateNewId(),
          cardHolder: currentCard.value.cardHolder,
          iban: currentCard.value.iban,
          swiftCode: currentCard.value.swiftCode,
          bankName: currentCard.value.bankName,
        );

        print('Adding new IBAN card with ID: ${newCard.id}');

        await _ibanCardService.addIbanCard(newCard);
        Get.back();
        Get.context?.showSuccessSnackBar('IBAN card added successfully');
      }

      // IBAN kartları yeniden yükle
      final ibanCardController = Get.find<IbanCardController>();
      ibanCardController.loadIbanCards();
      resetCard();
    } catch (e) {
      print('Error saving IBAN card: $e');
      Get.context
          ?.showErrorSnackBar('Failed to save IBAN card: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  void resetCard() {
    currentCard.value = IbanCard(
      id: _generateNewId(),
      cardHolder: "",
      iban: "",
      swiftCode: "",
      bankName: "",
    );
    isEditMode.value = false;
    _originalCard = null;
    currentCard.refresh();
  }
}
