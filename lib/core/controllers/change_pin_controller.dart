import 'package:get/get.dart';
import 'package:wallet_app/core/data/local_services/auth_services/authentication_service.dart';

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
        Get.snackbar('Error', 'Current PIN is incorrect',
            backgroundColor: Get.theme.colorScheme.error);
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred during verification');
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
      Get.snackbar('Success', 'PIN changed successfully',
          backgroundColor: Get.theme.primaryColor);
    } catch (e) {
      Get.snackbar('Error', 'Failed to change PIN');
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
