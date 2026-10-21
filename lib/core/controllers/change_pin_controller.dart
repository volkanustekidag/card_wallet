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

  /// Goes through [AuthController.verifyPin] so the change-PIN screen shares
  /// the lock screen's rate limiting (3/5/7/10 failures → lockout). Checking
  /// the hash directly here would give an attacker unlimited guesses.
  Future<void> verifyCurrentPin(String pin) async {
    final auth = Get.find<AuthController>();
    final lockedBefore = auth.isPinLocked;
    isLoading.value = true;
    try {
      final ok = await auth.verifyPin(pin);
      if (ok) {
        currentPinVerified.value = true;
        verificationFailed.value = false;
        return;
      }
      verificationFailed.value = true;
      // verifyPin already explained an active lockout; only add the
      // "wrong PIN" hint for a plain miss.
      if (!lockedBefore && !auth.isPinLocked) {
        Get.context?.showErrorSnackBar('currentPinIncorrect'.tr());
      }
    } finally {
      isLoading.value = false;
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
