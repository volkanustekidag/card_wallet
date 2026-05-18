import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/controllers/auth_controller.dart';
import 'package:wallet_app/core/data/local_services/auth_services/authentication_service.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';

class ChangePinController extends GetxController {
  final AuthenticationService _authenticationService;

  ChangePinController(this._authenticationService);

  var isLoading = false.obs;
  var currentPinVerified = false.obs;
  var pinChangeCompleted = false.obs;
  var verificationFailed = false.obs;

  /// Mirrors our [isLoading] onto [AuthController.isLoading] so the shared
  /// [AuthViews] component shows its spinner during the PBKDF2 hash —
  /// AuthViews binds to AuthController, not to this controller, so without
  /// the bridge the user sees a frozen field with no feedback while the
  /// hash crunches in the background isolate.
  void _setBusy(bool busy) {
    isLoading.value = busy;
    if (Get.isRegistered<AuthController>()) {
      Get.find<AuthController>().isLoading.value = busy;
    }
  }

  Future<void> verifyCurrentPin(String pin) async {
    try {
      _setBusy(true);
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
      _setBusy(false);
    }
  }

  Future<void> saveNewPin(String newPin) async {
    try {
      _setBusy(true);
      await _authenticationService.updatePin(newPin);
      pinChangeCompleted.value = true;

      Get.back();
      Get.context?.showSuccessSnackBar('pinChangedSuccessfully'.tr());
    } catch (e) {
      Get.context?.showErrorSnackBar('failedToChangePin'.tr());
    } finally {
      _setBusy(false);
    }
  }

  void resetStates() {
    currentPinVerified.value = false;
    pinChangeCompleted.value = false;
    verificationFailed.value = false;
  }
}
