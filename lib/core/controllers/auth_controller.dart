import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart' hide Trans;
import 'package:local_auth/local_auth.dart';
import 'package:wallet_app/core/data/local_services/auth_services/authentication_service.dart';
import 'package:wallet_app/core/data/local_services/auth_services/biometric_service.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';

class AuthController extends GetxController {
  final AuthenticationService _authenticationService = AuthenticationService();
  final BiometricService _biometricService = BiometricService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _pinFailureCountKey = 'pin_failure_count';
  static const String _pinLockedUntilKey = 'pin_locked_until';

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

  // Rate limiting state
  final pinFailureCount = 0.obs;
  final pinLockedUntil = Rxn<DateTime>();
  Timer? _lockTicker;

  @override
  void onInit() {
    super.onInit();
    checkHavePassword();
    checkBiometricAvailability();
    loadAutoLockTime();
    _restoreRateLimitState();
  }

  @override
  void onClose() {
    _lockTicker?.cancel();
    super.onClose();
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
    if (isPinLocked) {
      Get.context?.showErrorSnackBar(
        'pinLockedMessage'.tr(args: [_formatLockRemaining()]),
      );
      authenticationFailed.value = true;
      return;
    }
    try {
      isLoading.value = true;
      final result = await _authenticationService.authenticate(password);

      if (result == true) {
        await _resetRateLimitState();
        authenticationSuccess.value = true;
        Get.offAllNamed('/home');
      } else {
        await _registerPinFailure();
        authenticationFailed.value = true;
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

  // -------------------------------------------------------------------------
  // PIN rate limiting
  // -------------------------------------------------------------------------

  bool get isPinLocked {
    final until = pinLockedUntil.value;
    return until != null && until.isAfter(DateTime.now());
  }

  Duration get pinLockRemaining {
    final until = pinLockedUntil.value;
    if (until == null) return Duration.zero;
    final delta = until.difference(DateTime.now());
    return delta.isNegative ? Duration.zero : delta;
  }

  String _formatLockRemaining() {
    final secs = pinLockRemaining.inSeconds;
    if (secs >= 60) {
      final minutes = (secs / 60).ceil();
      return '$minutes min';
    }
    return '$secs s';
  }

  Future<void> _restoreRateLimitState() async {
    try {
      final countStr = await _secureStorage.read(key: _pinFailureCountKey);
      pinFailureCount.value = int.tryParse(countStr ?? '') ?? 0;

      final untilStr = await _secureStorage.read(key: _pinLockedUntilKey);
      if (untilStr != null) {
        final until = DateTime.tryParse(untilStr);
        if (until != null && until.isAfter(DateTime.now())) {
          pinLockedUntil.value = until;
          _startLockTicker();
        } else if (until != null) {
          // Lock expired between sessions; clear it.
          await _secureStorage.delete(key: _pinLockedUntilKey);
          pinLockedUntil.value = null;
        }
      }
    } catch (_) {
      // Best-effort restore; ignore failures.
    }
  }

  Future<void> _registerPinFailure() async {
    pinFailureCount.value += 1;
    await _secureStorage.write(
      key: _pinFailureCountKey,
      value: pinFailureCount.value.toString(),
    );

    final lockSeconds = _lockSecondsFor(pinFailureCount.value);
    if (lockSeconds > 0) {
      final until = DateTime.now().add(Duration(seconds: lockSeconds));
      pinLockedUntil.value = until;
      await _secureStorage.write(
        key: _pinLockedUntilKey,
        value: until.toIso8601String(),
      );
      _startLockTicker();
    }
  }

  Future<void> _resetRateLimitState() async {
    pinFailureCount.value = 0;
    pinLockedUntil.value = null;
    _lockTicker?.cancel();
    _lockTicker = null;
    try {
      await _secureStorage.delete(key: _pinFailureCountKey);
      await _secureStorage.delete(key: _pinLockedUntilKey);
    } catch (_) {}
  }

  /// Lock duration policy. Quiet for the first two attempts so a fat-finger
  /// does not get punished.
  int _lockSecondsFor(int failureCount) {
    if (failureCount >= 10) return 30 * 60; // 30 minutes
    if (failureCount >= 7) return 5 * 60; // 5 minutes
    if (failureCount >= 5) return 60; // 1 minute
    if (failureCount >= 3) return 30; // 30 seconds
    return 0;
  }

  void _startLockTicker() {
    _lockTicker?.cancel();
    _lockTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isPinLocked) {
        timer.cancel();
        _lockTicker = null;
        pinLockedUntil.refresh();
        return;
      }
      pinLockedUntil.refresh();
    });
  }
}
