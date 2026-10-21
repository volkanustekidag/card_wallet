import 'package:flutter/scheduler.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/services/error_reporter.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/iban_card_service.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';

class IbanCardController extends GetxController {
  final IbanCardService _ibanCardService = IbanCardService();

  IbanCardController();

  var ibanCards = <IbanCard>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Seed from HomeController so the route transition has real content
    // on its first frame. Hive reload runs after the first frame so the
    // box read doesn't compete with the fade-in for UI thread time.
    if (Get.isRegistered<HomeController>()) {
      final home = Get.find<HomeController>();
      if (home.ibanCards.isNotEmpty) {
        ibanCards.assignAll(home.ibanCards);
      }
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      loadIbanCards();
    });
  }

  Future<void> loadIbanCards() async {
    try {
      if (ibanCards.isEmpty) {
        isLoading.value = true;
      }
      await _ibanCardService.openBox();
      final result = await _ibanCardService.getAllIbanCards();
      ibanCards.value = result;
    } catch (e, st) {
      ErrorReporter.report(e, st, reason: 'loadIbanCards');
      Get.context?.showErrorSnackBar('failedToLoadIbanCards'.tr());
      // Keep whatever was seeded — don't blank on error.
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeIbanCard(IbanCard ibanCard) async {
    try {
      await _ibanCardService.removeIbanCard(ibanCard);
      ibanCards.remove(ibanCard);
      Get.context?.showSuccessSnackBar('ibanCardDeletedSuccessfully'.tr());
    } catch (e, st) {
      ErrorReporter.report(e, st, reason: 'removeIbanCard');
      Get.context?.showErrorSnackBar('failedToDeleteIbanCard'.tr());
    }
  }

  Future<void> addIbanCard(IbanCard ibanCard) async {
    try {
      await _ibanCardService.openBox();
      await _ibanCardService.addIbanCard(ibanCard);
      await loadIbanCards();
      Get.context?.showSuccessSnackBar('ibanCardAddedSuccessfully'.tr());
    } catch (e, st) {
      ErrorReporter.report(e, st, reason: 'addIbanCard');
      Get.context?.showErrorSnackBar('failedToAddIbanCard'.tr());
    }
  }
}
