import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/feature/credit_cards/controller/credit_card_controller.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/dialogs/card_limit_dialog.dart';
import 'package:wallet_app/core/enums/card_limit_type.dart';
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_service.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/utils/validators.dart';
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
  bool get isFormValid => _isCardValid(currentCard.value);

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

    debugPrint(
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

      // Soft validation: warn but allow saving anyway.
      final warnings = _collectValidationWarnings(currentCard.value);
      if (warnings.isNotEmpty) {
        final shouldProceed = await _confirmSaveDespiteWarnings(warnings);
        if (shouldProceed != true) {
          return;
        }
      }

      await _creditCardService.openBox();

      // Premium kontrolü sadece yeni kart eklerken
      if (!isEditMode.value) {
        final premiumController = Get.find<PremiumController>();
        final currentCount =
            await premiumController.getStoredCardCount(CardLimitType.credit);

        if (!premiumController.canAddMoreCreditCards(currentCount)) {
          final dialogContext = Get.context;
          if (dialogContext == null) {
            Get.toNamed('/premium');
            return;
          }

          final unlocked =
              await showCardLimitDialog(dialogContext, CardLimitType.credit);
          if (!unlocked) {
            return;
          }
        }
      }

      if (isEditMode.value && _originalCard != null) {
        // Güncelleme işlemi - orijinal ID'yi koru
        final updatedCard = CreditCard(
          id: _originalCard!.id,
          bankName: currentCard.value.bankName,
          creditCardNumber: currentCard.value.creditCardNumber,
          cardHolder: currentCard.value.cardHolder,
          expirationDate: currentCard.value.expirationDate,
          cvc2: currentCard.value.cvc2,
          cardColorId: currentCard.value.cardColorId,
        );

        await _creditCardService.updateCreditCard(_originalCard!, updatedCard);
        HapticFeedback.mediumImpact();
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
        HapticFeedback.mediumImpact();
        Get.back();
        Get.context?.showSuccessSnackBar("creditCardAddedSuccessfully".tr());
      }

      final creditCardController = Get.find<CreditCardController>();
      creditCardController.loadCreditCards();
      resetCard();
    } catch (e) {
      debugPrint('Error saving card: $e');
      Get.context?.showErrorSnackBar(
          "failedToSaveCreditCard".tr(args: [e.toString()]));
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

  bool _isCardValid(CreditCard card) {
    final sanitizedNumber = card.creditCardNumber.replaceAll(RegExp(r'\s+'), '');
    final expirationPattern = RegExp(r'^\d{2}\s?\/\s?\d{2}$');

    return card.bankName.trim().isNotEmpty &&
        sanitizedNumber.length >= 16 &&
        card.cardHolder.trim().isNotEmpty &&
        expirationPattern.hasMatch(card.expirationDate.trim()) &&
        card.cvc2.trim().length >= 3 &&
        card.cvc2.trim().length <= 4;
  }

  List<String> _collectValidationWarnings(CreditCard card) {
    final warnings = <String>[];
    if (!CardValidators.isValidLuhn(card.creditCardNumber)) {
      warnings.add('warningInvalidCardNumber'.tr());
    }
    if (!CardValidators.isValidExpiration(card.expirationDate)) {
      warnings.add('warningInvalidExpiration'.tr());
    }
    return warnings;
  }

  Future<bool?> _confirmSaveDespiteWarnings(List<String> warnings) {
    final dialogContext = Get.context;
    if (dialogContext == null) return Future.value(true);
    return Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'validationWarningTitle'.tr(),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'validationWarningSubtitle'.tr(),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            for (final w in warnings)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '• $w',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('reviewAgain'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: Text('saveAnyway'.tr()),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
