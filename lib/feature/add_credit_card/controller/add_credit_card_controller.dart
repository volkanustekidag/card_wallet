import 'package:get/get.dart' hide Trans;
import 'package:flutter/material.dart';
import 'package:wallet_app/feature/credit_cards/controller/credit_card_controller.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_service.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';

class AddCreditCardController extends GetxController {
  final CreditCardService _creditCardService = CreditCardService();

  var currentCard = CreditCard(
    id: "",
    bankName: "",
    creditCardNumber: "",
    cardHolder: "",
    expirationDate: "",
    cvc2: "",
    cardColorId: 1,
  ).obs;
  var isLoading = false.obs;
  var isEditMode = false.obs;
  CreditCard? _originalCard;

  // Benzersiz string ID oluştur
  String _generateNewId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (1000 + (999 * (DateTime.now().microsecond / 1000000)).round())
            .toString();
  }

  // Edit modu için başlatma
  void initializeForEdit(CreditCard card) {
    _originalCard = card;

    // Kartın verilerini kopyala - currentCard'ı güncelleyince form otomatik dolacak
    currentCard.value = CreditCard(
      id: card.id, // Orijinal ID'yi koru
      bankName: card.bankName,
      creditCardNumber: card.creditCardNumber,
      cardHolder: card.cardHolder,
      expirationDate: card.expirationDate,
      cvc2: card.cvc2,
      cardColorId: card.cardColorId,
    );

    isEditMode.value = true;

    // Trigger refresh to ensure UI updates
    currentCard.refresh();

    print(
        'Edit mode initialized for card: ${card.bankName} - ${card.creditCardNumber}');
  }

  // Yeni kart oluşturma modu için başlatma
  void initializeForCreate() {
    _originalCard = null;
    currentCard.value = CreditCard(
      id: _generateNewId(),
      bankName: "",
      creditCardNumber: "",
      cardHolder: "",
      expirationDate: "",
      cvc2: "",
      cardColorId: 1,
    );
    isEditMode.value = false;

    // Trigger refresh
    currentCard.refresh();
  }

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

    currentCard.refresh();
  }

  Future<void> saveCard() async {
    try {
      isLoading.value = true;
      await _creditCardService.openBox();

      // Premium kontrolü sadece yeni kart eklerken
      if (!isEditMode.value) {
        final creditCardController = Get.put(CreditCardController());
        final premiumController = Get.find<PremiumController>();

        final currentCount = creditCardController.creditCards.length;
        if (!premiumController.canAddMoreCreditCards(currentCount)) {
          // Direkt premium sayfasına yönlendir
          Get.toNamed('/premium');
          return;
        }
      }

      if (isEditMode.value && _originalCard != null) {
        // Güncelleme işlemi
        final updatedCard = CreditCard(
          id: _generateNewId(),
          bankName: currentCard.value.bankName,
          creditCardNumber: currentCard.value.creditCardNumber,
          cardHolder: currentCard.value.cardHolder,
          expirationDate: currentCard.value.expirationDate,
          cvc2: currentCard.value.cvc2,
          cardColorId: currentCard.value.cardColorId,
        );

        await _creditCardService.updateCreditCard(_originalCard!, updatedCard);
        Get.back();
        Get.context?.showSuccessSnackBar("creditCardUpdatedSuccessfully".tr());
      } else {
        // Yeni kart ekleme işlemi
        final newCard = CreditCard(
          id: _generateNewId(),
          bankName: currentCard.value.bankName,
          creditCardNumber: currentCard.value.creditCardNumber,
          cardHolder: currentCard.value.cardHolder,
          expirationDate: currentCard.value.expirationDate,
          cvc2: currentCard.value.cvc2,
          cardColorId: currentCard.value.cardColorId,
        );

        await _creditCardService.addToCreditCard(newCard);
        Get.back();
        Get.context?.showSuccessSnackBar("creditCardAddedSuccessfully".tr());
      }

      final creditCardController = Get.find<CreditCardController>();
      creditCardController.loadCreditCards();
      resetCard();
    } catch (e) {
      print('Error saving card: $e');
      Get.context?.showErrorSnackBar("failedToSaveCreditCard".tr(args: [e.toString()]));
    } finally {
      isLoading.value = false;
    }
  }

  void resetCard() {
    currentCard.value = CreditCard(
      id: _generateNewId(),
      bankName: "",
      creditCardNumber: "",
      cardHolder: "",
      expirationDate: "",
      cvc2: "",
      cardColorId: 1,
    );
    isEditMode.value = false;
    _originalCard = null;
    currentCard.refresh();
  }
}
