import 'package:easy_localization/easy_localization.dart';
import 'package:get/get.dart' hide Trans;
import 'package:local_auth/local_auth.dart';
import 'package:wallet_app/core/data/local_services/auth_services/authentication_service.dart';
import 'package:wallet_app/core/data/local_services/auth_services/biometric_service.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';

class AuthController extends GetxController {
  final AuthenticationService _authenticationService = AuthenticationService();
  final BiometricService _biometricService = BiometricService();

  AuthController();

  var isLoading = false.obs;
  var isRegistering = false.obs;
  var hasPassword = false.obs;
  var authenticationSuccess = false.obs;
  var authenticationFailed = false.obs;

  // Biometric states
  var isBiometricAvailable = false.obs;
  var isBiometricEnabled = false.obs;
  var availableBiometrics = <BiometricType>[].obs;
  var showBiometricButton = false.obs;
  var autoLockTime = 5.obs;

  @override
  void onInit() {
    super.onInit();
    checkHavePassword();
    checkBiometricAvailability();
    loadAutoLockTime();
  }

  Future<void> checkHavePassword() async {
    try {
      isLoading.value = true;
      await _authenticationService.openBox();
      final result = await _authenticationService.checkHavePassword();

      if (result == null) {
        isRegistering.value = true;
        hasPassword.value = false;
      } else {
        hasPassword.value = true;
        isRegistering.value = false;
      }

      // After checking password, update biometric button visibility
      await checkBiometricAvailability();
    } catch (e) {
      Get.context
          ?.showErrorSnackBar('errorCheckingPassword'.tr());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login(String password) async {
    try {
      isLoading.value = true;
      final result = await _authenticationService.authenticate(password);

      if (result == true) {
        authenticationSuccess.value = true;
        Get.offAllNamed('/home');
      } else {
        authenticationFailed.value = true;
        // Don't show snackbar here, let the UI handle the error display
      }
    } catch (e) {
      Get.context?.showErrorSnackBar('errorDuringAuthentication'.tr());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register(String password) async {
    try {
      isLoading.value = true;
      await _authenticationService.creatPassword(password);
      isRegistering.value = false;
      hasPassword.value = true;
    } catch (e) {
      Get.context?.showErrorSnackBar('errorDuringRegistration'.tr());
    } finally {
      isLoading.value = false;
    }
  }

  void resetAuthenticationState() {
    authenticationFailed.value = false;
    authenticationSuccess.value = false;
  }

  /// Check biometric availability and update states
  Future<void> checkBiometricAvailability() async {
    try {
      isBiometricAvailable.value =
          await _biometricService.isBiometricAvailable();
      availableBiometrics.value =
          await _biometricService.getAvailableBiometrics();
      isBiometricEnabled.value = await _biometricService.isBiometricEnabled();

      // Show biometric button only if available, enabled, and user has password
      showBiometricButton.value = isBiometricAvailable.value &&
          isBiometricEnabled.value &&
          hasPassword.value;
    } catch (e) {
      isBiometricAvailable.value = false;
      isBiometricEnabled.value = false;
      showBiometricButton.value = false;
    }
  }

  /// Authenticate using biometric
  Future<void> authenticateWithBiometric() async {
    try {
      isLoading.value = true;

      final success = await _biometricService.authenticateWithBiometric(
        localizedReason: 'biometricAuthReason'.tr(),
      );

      if (success) {
        authenticationSuccess.value = true;
        Get.offAllNamed('/home');
      } else {
        authenticationFailed.value = true;
      }
    } on BiometricException catch (e) {
      Get.context?.showErrorSnackBar(e.message);
      authenticationFailed.value = true;
    } catch (e) {
      Get.context
          ?.showErrorSnackBar('biometricAuthError'.tr());
      authenticationFailed.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  /// Enable or disable biometric authentication
  Future<void> toggleBiometric(bool enabled) async {
    try {
      if (enabled) {
        // Check if biometric is available first
        final isAvailable = await _biometricService.isBiometricAvailable();
        if (!isAvailable) {
          Get.context
              ?.showErrorSnackBar('biometricNotSupportedDevice'.tr());
          return;
        }

        // Temporarily enable biometric to test authentication
        await _biometricService.setBiometricEnabled(true);

        try {
          // Test authenticate with biometric to ensure it works
          final success = await _biometricService.authenticateWithBiometric(
            localizedReason: 'biometricEnableAuthReason'.tr(),
          );

          if (success) {
            isBiometricEnabled.value = true;
            showBiometricButton.value = true;
            Get.context
                ?.showSuccessSnackBar('biometricEnabled'.tr());
          } else {
            // If authentication failed, disable it again
            await _biometricService.setBiometricEnabled(false);
            isBiometricEnabled.value = false;
            showBiometricButton.value = false;
            Get.context?.showErrorSnackBar('biometricAuthFailed'.tr());
          }
        } catch (e) {
          // If any error occurs, disable it again
          await _biometricService.setBiometricEnabled(false);
          isBiometricEnabled.value = false;
          showBiometricButton.value = false;
          throw e;
        }
      } else {
        await _biometricService.setBiometricEnabled(false);
        isBiometricEnabled.value = false;
        showBiometricButton.value = false;
        Get.context
            ?.showSuccessSnackBar('biometricDisabled'.tr());
      }
    } on BiometricException catch (e) {
      Get.context?.showErrorSnackBar(e.message);
    } catch (e) {
      Get.context?.showErrorSnackBar('biometricSettingChangeError'.tr() + ': $e');
    }
  }

  /// Get biometric type display name
  String getBiometricDisplayName() {
    return _biometricService.getBiometricTypeDisplayName(availableBiometrics);
  }

  /// Check if app should be locked based on auto-lock timer
  Future<bool> shouldLockApp() async {
    try {
      return await _biometricService.shouldLockApp();
    } catch (e) {
      return true; // Default to locked if error
    }
  }

  /// Update last active time (call this on user interaction)
  Future<void> updateLastActiveTime() async {
    try {
      await _biometricService.updateLastActiveTime();
    } catch (e) {
      // Silent fail - not critical
    }
  }

  /// Load auto-lock time from storage
  Future<void> loadAutoLockTime() async {
    try {
      final time = await _biometricService.getAutoLockTime();
      autoLockTime.value = time;
    } catch (e) {
      autoLockTime.value = 5; // Default value
    }
  }

  /// Update auto-lock time
  Future<void> updateAutoLockTime(int time) async {
    try {
      await _biometricService.setAutoLockTime(time);
      autoLockTime.value = time;
    } catch (e) {
      Get.context?.showErrorSnackBar('autoLockTimeUpdateError'.tr());
    }
  }
}
