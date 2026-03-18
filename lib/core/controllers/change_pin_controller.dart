import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/data/local_services/auth_services/authentication_service.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';

class ChangePinController extends GetxController {
  final AuthenticationService _authenticationService;

  ChangePinController(this._authenticationService);

  var isLoading = false.obs;
  var currentPinVerified = false.obs;
  var pinChangeCompleted = false.obs;
  var verificationFailed = false.obs;

  Future<void> verifyCurrentPin(String pin) async {
    try {
      isLoading.value = true;
      await _authenticationService.openBox();
      final result = await _authenticationService.authenticate(pin);

      if (result == true) {
        currentPinVerified.value = true;
        verificationFailed.value = false;
      } else {
        verificationFailed.value = true;
        Get.context?.showErrorSnackBar('currentPinIncorrect'.tr());
      }
    } catch (e) {
      Get.context?.showErrorSnackBar('verificationError'.tr());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveNewPin(String newPin) async {
    try {
      isLoading.value = true;
      await _authenticationService.updatePin(newPin);
      pinChangeCompleted.value = true;

      Get.back();
      Get.context?.showSuccessSnackBar('pinChangedSuccessfully'.tr());
    } catch (e) {
      Get.context?.showErrorSnackBar('failedToChangePin'.tr());
    } finally {
      isLoading.value = false;
    }
  }

  void resetStates() {
    currentPinVerified.value = false;
    pinChangeCompleted.value = false;
    verificationFailed.value = false;
  }
}
