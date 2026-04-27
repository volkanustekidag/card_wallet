import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/feature/iban_card/controller/iban_card_controller.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/dialogs/card_limit_dialog.dart';
import 'package:wallet_app/core/enums/card_limit_type.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/iban_card_service.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/utils/validators.dart';
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

    debugPrint(
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

    debugPrint('Create mode initialized for IBAN card');
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

      // Soft IBAN validation: warn but allow saving anyway.
      if (!IbanValidator.isValid(currentCard.value.iban)) {
        final shouldProceed = await _confirmSaveDespiteWarnings(
          ['warningInvalidIban'.tr()],
        );
        if (shouldProceed != true) {
          return;
        }
      }

      await _ibanCardService.openBox();

      // Premium kontrolü sadece yeni kart eklerken
      if (!isEditMode.value) {
        final premiumController = Get.find<PremiumController>();

        final currentCount =
            await premiumController.getStoredCardCount(CardLimitType.iban);

        if (!premiumController.canAddMoreIbanCards(currentCount)) {
          final dialogContext = Get.context;
          if (dialogContext == null) {
            Get.toNamed('/premium');
            return;
          }

          final unlocked =
              await showCardLimitDialog(dialogContext, CardLimitType.iban);
          if (!unlocked) {
            return;
          }
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
        HapticFeedback.mediumImpact();
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

        debugPrint('Adding new IBAN card with ID: ${newCard.id}');

        await _ibanCardService.addIbanCard(newCard);
        HapticFeedback.mediumImpact();
        Get.back();
        Get.context?.showSuccessSnackBar('IBAN card added successfully');
      }

      // IBAN kartları yeniden yükle
      final ibanCardController = Get.find<IbanCardController>();
      ibanCardController.loadIbanCards();
      resetCard();
    } catch (e) {
      debugPrint('Error saving IBAN card: $e');
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
