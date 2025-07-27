import 'package:get/get.dart';
import 'package:flutter/material.dart';
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
        Get.context?.showErrorSnackBar('Current PIN is incorrect');
      }
    } catch (e) {
      Get.context?.showErrorSnackBar('An error occurred during verification');
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
      Get.context?.showSuccessSnackBar('PIN changed successfully');
    } catch (e) {
      Get.context?.showErrorSnackBar('Failed to change PIN');
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
