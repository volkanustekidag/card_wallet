import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/components/dialog/delete_dialog.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/feature/credit_cards/controller/credit_card_controller.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/dialogs/card_limit_dialog.dart';
import 'package:wallet_app/core/enums/card_limit_type.dart';
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/iban_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/loyalty_card/loyalty_card_service.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/services/analytics_service.dart';
import 'package:wallet_app/core/utils/session_prompt_gate.dart';
import 'package:wallet_app/core/utils/card_number_layout.dart';
import 'package:wallet_app/core/utils/validators.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/services/error_reporter.dart';
import 'package:wallet_app/core/services/ui_prefs.dart';

class AddCreditCardController extends GetxController {
  final CreditCardService _creditCardService = CreditCardService();

  var currentCard = CreditCard(
    id: "",
    bankName: "",
    creditCardNumber: "",
    cardHolder: "",
    expirationDate: "",
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
      cardColorId: card.cardColorId,
      createdAt: card.createdAt,
      notes: card.notes,
      tags: card.tags == null ? null : List<String>.from(card.tags!),
      expiryReminderEnabled: card.expiryReminderEnabled,
      expiryReminderDaysBefore: card.expiryReminderDaysBefore,
      paymentReminderEnabled: card.paymentReminderEnabled,
      paymentDueDay: card.paymentDueDay,
      paymentReminderDaysBefore: card.paymentReminderDaysBefore,
      reminderHour: card.reminderHour,
    );

    isEditMode.value = true;

    // Trigger refresh to ensure UI updates
    currentCard.refresh();
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
      cardColorId: 1,
      // On when the user asked for reminders during onboarding.
      expiryReminderEnabled: UiPrefs.instance.remindByDefault.value,
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
      case "notes":
        card.notes = value as String?;
        break;
      case "tags":
        card.tags = value as List<String>?;
        break;
      case "expiryReminderEnabled":
        card.expiryReminderEnabled = value as bool;
        if (value) AnalyticsService.instance.logReminderEnabled('expiry');
        break;
      case "expiryReminderDaysBefore":
        card.expiryReminderDaysBefore = value as int;
        break;
      case "paymentReminderEnabled":
        card.paymentReminderEnabled = value as bool;
        if (value) AnalyticsService.instance.logReminderEnabled('payment');
        break;
      case "paymentDueDay":
        card.paymentDueDay = value as int?;
        break;
      case "paymentReminderDaysBefore":
        card.paymentReminderDaysBefore = value as int;
        break;
      case "reminderHour":
        card.reminderHour = value as int;
        break;
    }

    currentCard.refresh();
  }

  /// Saves and pops the form. True when a card was written.
  Future<bool> saveCard() async {
    var saved = false;
    // A second tap can land before Obx rebuilds the disabled button; without
    // this guard both calls run and two cards with different ids are added.
    if (isLoading.value) return false;
    try {
      isLoading.value = true;
      final wasEditMode = isEditMode.value;

      // Soft validation: warn but allow saving anyway.
      final warnings = _collectValidationWarnings(currentCard.value);
      if (warnings.isNotEmpty) {
        final shouldProceed = await _confirmSaveDespiteWarnings(warnings);
        if (shouldProceed != true) {
          return false;
        }
      }

      await _creditCardService.openBox();
      // Premium kontrolü sadece yeni kart eklerken
      if (!wasEditMode) {
        final premiumController = Get.find<PremiumController>();
        final currentCount =
            await premiumController.getStoredCardCount(CardLimitType.credit);

        if (!premiumController.canAddMoreCreditCards(currentCount)) {
          final dialogContext = Get.context;
          if (dialogContext == null) {
            Get.toNamed('/premium');
            return false;
          }

          final unlocked =
              await showCardLimitDialog(dialogContext, CardLimitType.credit);
          if (!unlocked) {
            return false;
          }
        }
      }

      if (wasEditMode && _originalCard != null) {
        // Güncelleme işlemi - orijinal ID ve createdAt korunur
        final updatedCard = CreditCard(
          id: _originalCard!.id,
          bankName: currentCard.value.bankName,
          creditCardNumber: currentCard.value.creditCardNumber,
          cardHolder: currentCard.value.cardHolder,
          expirationDate: currentCard.value.expirationDate,
          cardColorId: currentCard.value.cardColorId,
          createdAt: _originalCard!.createdAt ?? DateTime.now(),
          notes: currentCard.value.notes,
          tags: currentCard.value.tags,
          expiryReminderEnabled: currentCard.value.expiryReminderEnabled,
          expiryReminderDaysBefore: currentCard.value.expiryReminderDaysBefore,
          paymentReminderEnabled: currentCard.value.paymentReminderEnabled,
          paymentDueDay: currentCard.value.paymentDueDay,
          paymentReminderDaysBefore:
              currentCard.value.paymentReminderDaysBefore,
          reminderHour: currentCard.value.reminderHour,
        );

        await _creditCardService.updateCreditCard(_originalCard!, updatedCard);
        saved = true;
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
          cardColorId: currentCard.value.cardColorId,
          createdAt: DateTime.now(),
          notes: currentCard.value.notes,
          tags: currentCard.value.tags,
          expiryReminderEnabled: currentCard.value.expiryReminderEnabled,
          expiryReminderDaysBefore: currentCard.value.expiryReminderDaysBefore,
          paymentReminderEnabled: currentCard.value.paymentReminderEnabled,
          paymentDueDay: currentCard.value.paymentDueDay,
          paymentReminderDaysBefore:
              currentCard.value.paymentReminderDaysBefore,
          reminderHour: currentCard.value.reminderHour,
        );

        await _creditCardService.addToCreditCard(newCard);
        saved = true;
        unawaited(
          AnalyticsService.instance.logCardAdded(AnalyticsCardType.credit),
        );
        HapticFeedback.mediumImpact();
        Get.back();
        Get.context?.showSuccessSnackBar("creditCardAddedSuccessfully".tr());
      }

      final creditCardController = Get.find<CreditCardController>();
      creditCardController.loadCreditCards();
      resetCard();

      if (!wasEditMode) {
        // Trigger the post-add PIN nudge once the user has their very first
        // card. We read all three boxes directly so the count is correct
        // even before HomeController's debounced refresh fires.
        try {
          final cc = await CreditCardService().getAllCreditCards();
          final iban = await IbanCardService().getAllIbanCards();
          final loyalty = await LoyaltyCardService().getAllLoyaltyCards();
          final total = cc.length + iban.length + loyalty.length;
          unawaited(AnalyticsService.instance.setCardCountTotal(total));
          // One prompt per session: PIN > widget tutorial > rating.
          await PostAddPrompts().run(totalCards: total);
        } catch (_) {
          // Best-effort prompt; failure here must never break the save.
        }
      }
    } catch (e, st) {
      ErrorReporter.report(e, st, reason: 'saveCreditCard');
      Get.context?.showErrorSnackBar("failedToSaveCreditCard".tr());
    } finally {
      isLoading.value = false;
    }
    return saved;
  }

  void resetCard() {
    currentCard.value = CreditCard(
      id: _generateNewId(),
      bankName: "",
      creditCardNumber: "",
      cardHolder: "",
      expirationDate: "",
      cardColorId: 1,
    );
    isEditMode.value = false;
    _originalCard = null;
    currentCard.refresh();
  }

  bool _isCardValid(CreditCard card) {
    final expirationPattern = RegExp(r'^\d{2}\s?\/\s?\d{2}$');

    // 13-19 digits depending on the network (Amex 15, Diners 14, Visa 13/16/19…).
    // The bank is optional: many issuers worldwide aren't in the BIN table,
    // and an unknown bank must not block a scanned card ([saveCard] names
    // it after the network instead).
    return CardNumberLayout.isValidLength(card.creditCardNumber) &&
        card.cardHolder.trim().isNotEmpty &&
        expirationPattern.hasMatch(card.expirationDate.trim());
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

  Future<bool?> _confirmSaveDespiteWarnings(List<String> warnings) async {
    final ctx = Get.context;
    if (ctx == null) return true;
    return showConfirmActionSheet(
      context: ctx,
      title: 'validationWarningTitle'.tr(),
      content: [
        'validationWarningSubtitle'.tr(),
        for (final w in warnings) '• $w',
      ].join('\n'),
      confirmText: 'saveAnyway'.tr(),
      cancelText: 'reviewAgain'.tr(),
      destructive: false,
      glyph: CwIcons.warning,
    );
  }
}
