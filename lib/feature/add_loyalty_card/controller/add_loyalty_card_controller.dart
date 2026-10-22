import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:uuid/uuid.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/iban_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/loyalty_card/loyalty_card_service.dart';
import 'package:wallet_app/core/dialogs/card_limit_dialog.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/enums/card_limit_type.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/services/analytics_service.dart';
import 'package:wallet_app/core/utils/session_prompt_gate.dart';
import 'package:wallet_app/feature/loyalty_card/controller/loyalty_card_controller.dart';

class AddLoyaltyCardController extends GetxController {
  static const _uuid = Uuid();
  final LoyaltyCardService _service = LoyaltyCardService();

  final currentCard = LoyaltyCard(
    id: '',
    name: '',
    barcode: '',
    barcodeFormat: 'CODE_128',
    colorId: 0,
  ).obs;
  final isLoading = false.obs;
  final isEditMode = false.obs;
  LoyaltyCard? _originalCard;

  bool get isFormValid {
    final c = currentCard.value;
    return c.name.trim().isNotEmpty && c.barcode.trim().isNotEmpty;
  }

  void initializeForCreate() {
    _originalCard = null;
    currentCard.value = LoyaltyCard(
      id: _uuid.v4(),
      name: '',
      brand: null,
      barcode: '',
      barcodeFormat: 'CODE_128',
      colorId: 0,
      logoAsset: null,
    );
    isEditMode.value = false;
    currentCard.refresh();
  }

  void initializeForEdit(LoyaltyCard card) {
    _originalCard = card;
    currentCard.value = LoyaltyCard(
      id: card.id,
      name: card.name,
      brand: card.brand,
      barcode: card.barcode,
      barcodeFormat: card.barcodeFormat,
      colorId: card.colorId,
      notes: card.notes,
      createdAt: card.createdAt,
      logoAsset: card.logoAsset,
      tags: card.tags == null ? null : List<String>.from(card.tags!),
      website: card.website,
    );
    isEditMode.value = true;
    currentCard.refresh();
  }

  void updateField(String field, dynamic value) {
    final c = currentCard.value;
    switch (field) {
      case 'name':
        c.name = value as String;
        break;
      case 'brand':
        c.brand = value as String?;
        break;
      case 'barcode':
        c.barcode = value as String;
        break;
      case 'barcodeFormat':
        c.barcodeFormat = value as String;
        break;
      case 'colorId':
        c.colorId = value as int;
        break;
      case 'notes':
        c.notes = value as String?;
        break;
      case 'logoAsset':
        c.logoAsset = value as String?;
        break;
      case 'website':
        c.website = value as String?;
        break;
    }
    currentCard.refresh();
  }

  /// The saved card for an edit: identity, creation date and usage stats
  /// from [original], everything the form can change from [draft] — including
  /// tags, which carry the favourite flag.
  @visibleForTesting
  static LoyaltyCard mergeEdit(LoyaltyCard original, LoyaltyCard draft) {
    return LoyaltyCard(
      id: original.id,
      name: draft.name,
      brand: draft.brand,
      barcode: draft.barcode,
      barcodeFormat: draft.barcodeFormat,
      colorId: draft.colorId,
      notes: draft.notes,
      createdAt: original.createdAt ?? DateTime.now(),
      logoAsset: draft.logoAsset,
      tags: draft.tags,
      website: draft.website,
      lastUsedAt: original.lastUsedAt,
      useCount: original.useCount,
    );
  }

  Future<void> saveCard() async {
    // Ignore a second tap that lands before the button rebuilds disabled.
    if (isLoading.value) return;
    try {
      isLoading.value = true;
      final wasEditMode = isEditMode.value;
      await _service.openBox();

      if (!wasEditMode) {
        final premium = Get.find<PremiumController>();
        final count = await premium.getStoredCardCount(CardLimitType.loyalty);
        if (!premium.canAddMoreLoyaltyCards(count)) {
          final ctx = Get.context;
          if (ctx == null) {
            Get.toNamed('/premium');
            return;
          }
          final unlocked =
              await showCardLimitDialog(ctx, CardLimitType.loyalty);
          if (!unlocked) return;
        }
      }

      if (wasEditMode && _originalCard != null) {
        final updated = mergeEdit(_originalCard!, currentCard.value);
        await _service.updateLoyaltyCard(_originalCard!, updated);
        HapticFeedback.mediumImpact();
        Get.back();
        Get.context?.showSuccessSnackBar('loyaltyCardUpdated');
      } else {
        final newCard = LoyaltyCard(
          id: currentCard.value.id.isEmpty ? _uuid.v4() : currentCard.value.id,
          name: currentCard.value.name,
          brand: currentCard.value.brand,
          barcode: currentCard.value.barcode,
          barcodeFormat: currentCard.value.barcodeFormat,
          colorId: currentCard.value.colorId,
          notes: currentCard.value.notes,
          createdAt: DateTime.now(),
          logoAsset: currentCard.value.logoAsset,
          tags: currentCard.value.tags,
          website: currentCard.value.website,
        );
        await _service.addLoyaltyCard(newCard);
        unawaited(
          AnalyticsService.instance.logCardAdded(AnalyticsCardType.loyalty),
        );
        HapticFeedback.mediumImpact();
        Get.back();
        Get.context?.showSuccessSnackBar('loyaltyCardAdded');
      }

      if (Get.isRegistered<LoyaltyCardController>()) {
        Get.find<LoyaltyCardController>().loadLoyaltyCards();
      }

      if (!wasEditMode) {
        // Trigger the post-add PIN nudge once the user has their very first
        // card. Read boxes directly so the count is correct ahead of the
        // HomeController debounce.
        try {
          final cc = await CreditCardService().getAllCreditCards();
          final iban = await IbanCardService().getAllIbanCards();
          final loyalty = await _service.getAllLoyaltyCards();
          final total = cc.length + iban.length + loyalty.length;
          unawaited(AnalyticsService.instance.setCardCountTotal(total));
          // One prompt per session: PIN > widget tutorial > rating.
          await PostAddPrompts().run(
            totalCards: total,
            loyaltyCount: loyalty.length,
          );
        } catch (_) {
          // Best-effort prompt; never break the save.
        }
      }
    } catch (e) {
      debugPrint('Error saving loyalty card: $e');
      Get.context?.showErrorSnackBar('failedToSaveLoyaltyCard');
    } finally {
      isLoading.value = false;
    }
  }
}
