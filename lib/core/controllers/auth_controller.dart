import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart' hide Trans;
import 'package:local_auth/local_auth.dart';
import 'package:wallet_app/core/data/local_services/auth_services/authentication_service.dart';
import 'package:wallet_app/core/data/local_services/auth_services/biometric_service.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/utils/secure_storage_provider.dart';

class AuthController extends GetxController {
  final AuthenticationService _authenticationService = AuthenticationService();
  final BiometricService _biometricService = BiometricService();
  final FlutterSecureStorage _secureStorage = SecureStorageProvider.instance;

  static const String _pinFailureCountKey = 'pin_failure_count';
  static const String _pinLockedUntilKey = 'pin_locked_until';
  static const Duration _pinErrorVisibleDuration = Duration(milliseconds: 700);

  AuthController();

  // `isLoading` is *only* set during an active login/register attempt — never
  // during the initial bootstrap. We resolve hasPassword synchronously below
  // so the lock screen can render on the first frame without a spinner.
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
  // Set after the async biometric availability/enabled probes resolve. The
  // lock screen waits on this before mounting the PIN field — otherwise the
  // PIN field auto-focuses for one frame, pops the keyboard, and only then
  // the biometric prompt slides in over it.
  var biometricInitDone = false.obs;
  var autoLockTime = 5.obs;

  // Rate limiting state
  final pinFailureCount = 0.obs;
  final pinLockedUntil = Rxn<DateTime>();
  Timer? _lockTicker;
  Timer? _errorResetTimer;

  /// Set when the user unlocks via biometric recovery (after forgetting the
  /// PIN). The home page reads this once on first build to nudge them toward
  /// resetting their PIN, then clears it via [consumeRecoveryPrompt].
  final recoveryPromptPending = false.obs;

  /// One-shot signal raised when the user crosses the first failed-attempt
  /// threshold. The lock screen listens, opens the recovery bottom sheet,
  /// and resets the flag — so dismissing the sheet once doesn't make it
  /// keep popping back up on every subsequent retry.
  final showRecoveryPrompt = false.obs;

  /// Whether the device has biometric enrollment, regardless of the app's
  /// own biometric toggle. Drives the "forgot PIN" affordance — we accept
  /// device biometric as proof of ownership for recovery even if the user
  /// never opted into biometric login.
  bool get isBiometricRecoveryAvailable =>
      isBiometricAvailable.value && hasPassword.value;

  @override
  void onInit() {
    super.onInit();
    // The auth box is opened in main() before runApp, so we can decide between
    // login and register UI synchronously — no spinner, no flicker.
    final hasExisting = _authenticationService.hasPasswordSync();
    hasPassword.value = hasExisting;
    isRegistering.value = !hasExisting;

    // Background-only work. None of these block the lock screen render: the
    // PIN field is interactive immediately, biometric button just appears
    // after the platform check resolves. Reconcile first so the biometric
    // probe doesn't read a stale "enabled=true" left behind by a previous
    // install before the cleanup write lands.
    unawaited(_bootstrapAuthState());
    unawaited(loadAutoLockTime());
  }

  Future<void> _bootstrapAuthState() async {
    await _reconcileStaleSecureStorage();
    await _initializeBiometrics();
    await _restoreRateLimitState();
  }

  /// iOS keeps `flutter_secure_storage` entries in the Keychain across app
  /// uninstalls, so a fresh reinstall can resurrect `biometric_enabled=true`
  /// and stale rate-limit counters from a previous lifetime — even though
  /// the Hive PIN box is gone. Biometric is conceptually a shortcut for an
  /// existing PIN; without one, none of these states should be active.
  /// Wipe them so the UI starts from a clean slate.
  Future<void> _reconcileStaleSecureStorage() async {
    if (hasPassword.value) return;
    try {
      await _biometricService.setBiometricEnabled(false);
    } catch (_) {}
    try {
      await _secureStorage.delete(key: _pinFailureCountKey);
      await _secureStorage.delete(key: _pinLockedUntilKey);
    } catch (_) {}
  }

  @override
  void onClose() {
    _lockTicker?.cancel();
    _errorResetTimer?.cancel();
    super.onClose();
  }

  Future<void> _initializeBiometrics() async {
    try {
      final available = await _biometricService.isBiometricAvailable();
      final biometrics = await _biometricService.getAvailableBiometrics();
      final enabled = await _biometricService.isBiometricEnabled();
      isBiometricAvailable.value = available;
      availableBiometrics.value = biometrics;
      isBiometricEnabled.value = enabled;
      showBiometricButton.value = available && enabled && hasPassword.value;
    } catch (_) {
      isBiometricAvailable.value = false;
      isBiometricEnabled.value = false;
      showBiometricButton.value = false;
    } finally {
      biometricInitDone.value = true;
    }
  }

  Future<void> login(String password) async {
    if (isPinLocked) {
      Get.context?.showErrorSnackBar(
        'pinLockedMessage'.tr(args: [_formatLockRemaining()]),
      );
      _flashAuthFailure();
      return;
    }
    isLoading.value = true;
    try {
      final result = await _authenticationService.authenticate(password);

      if (result == true) {
        await _resetRateLimitState();
        authenticationSuccess.value = true;
        // Navigate first; deliberately do *not* clear isLoading. The auth
        // route is being torn down — toggling state here would re-render the
        // PIN form for one frame between offAllNamed and the home route's
        // first paint, which is the "flash back to lock screen" the user
        // sees today.
        Get.offAllNamed('/home');
        return;
      }

      await _registerPinFailure();
      _flashAuthFailure();
    } catch (_) {
      Get.context?.showErrorSnackBar('errorDuringAuthentication'.tr());
      _flashAuthFailure();
    } finally {
      if (!authenticationSuccess.value) {
        isLoading.value = false;
      }
    }
  }

  Future<void> register(String password) async {
    isLoading.value = true;
    try {
      await _authenticationService.creatPassword(password);
      isRegistering.value = false;
      hasPassword.value = true;
      authenticationSuccess.value = true;
      Get.offAllNamed('/home');
    } catch (_) {
      Get.context?.showErrorSnackBar('errorDuringRegistration'.tr());
      _flashAuthFailure();
    } finally {
      if (!authenticationSuccess.value) {
        isLoading.value = false;
      }
    }
  }

  /// Verifies [pin] without navigating. Used by the settings "disable lock"
  /// flow and by [PinAction.verify]. Trips rate-limiting on failure, resets
  /// it on success — same security model as [login].
  Future<bool> verifyPin(String pin) async {
    if (isPinLocked) {
      Get.context?.showErrorSnackBar(
        'pinLockedMessage'.tr(args: [_formatLockRemaining()]),
      );
      _flashAuthFailure();
      return false;
    }
    isLoading.value = true;
    try {
      final result = await _authenticationService.authenticate(pin);
      if (result == true) {
        await _resetRateLimitState();
        return true;
      }
      await _registerPinFailure();
      _flashAuthFailure();
      return false;
    } catch (_) {
      Get.context?.showErrorSnackBar('errorDuringAuthentication'.tr());
      _flashAuthFailure();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Creates [pin] without navigating to /home. Used by [PinAction.create]
  /// when the user enables the lock from settings or accepts the post-add
  /// PIN prompt. Returns true on success.
  Future<bool> registerStandalone(String pin) async {
    isLoading.value = true;
    try {
      await _authenticationService.creatPassword(pin);
      isRegistering.value = false;
      hasPassword.value = true;
      return true;
    } catch (_) {
      Get.context?.showErrorSnackBar('errorDuringRegistration'.tr());
      _flashAuthFailure();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Removes the PIN entirely. Used by the settings "disable lock" flow
  /// after the user has verified their current PIN. Also disables biometric
  /// unlock — without a PIN there's nothing for biometric to substitute
  /// for. Resets rate-limit state so a fresh PIN starts clean later.
  Future<void> removePassword() async {
    await _authenticationService.deletePassword();
    hasPassword.value = false;
    isRegistering.value = true;
    if (isBiometricEnabled.value) {
      try {
        await _biometricService.setBiometricEnabled(false);
      } catch (_) {}
      isBiometricEnabled.value = false;
      showBiometricButton.value = false;
    }
    await _resetRateLimitState();
  }

  /// Trigger the PIN error UI: red border + shake + auto-clear (handled by the
  /// PIN component listening to [authenticationFailed]). The flag is reset
  /// after a short window so the red state is actually visible.
  void _flashAuthFailure() {
    authenticationFailed.value = true;
    _errorResetTimer?.cancel();
    _errorResetTimer = Timer(_pinErrorVisibleDuration, () {
      authenticationFailed.value = false;
    });
  }

  void resetAuthenticationState() {
    _errorResetTimer?.cancel();
    authenticationFailed.value = false;
    authenticationSuccess.value = false;
  }

  /// Authenticate using biometric
  Future<void> authenticateWithBiometric() async {
    isLoading.value = true;
    try {
      final success = await _biometricService.authenticateWithBiometric(
        localizedReason: 'biometricAuthReason'.tr(),
      );

      if (success) {
        authenticationSuccess.value = true;
        Get.offAllNamed('/home');
        return;
      }
      _flashAuthFailure();
    } on BiometricException catch (e) {
      Get.context?.showErrorSnackBar(e.message);
      _flashAuthFailure();
    } catch (_) {
      Get.context?.showErrorSnackBar('biometricAuthError'.tr());
      _flashAuthFailure();
    } finally {
      if (!authenticationSuccess.value) {
        isLoading.value = false;
      }
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

    // Exactly on the first lockout threshold, raise the recovery prompt
    // signal so the lock screen can offer biometric unlock. Restricted to
    // the equality check (not >=) so user-driven dismissals stay sticky
    // for the rest of the session.
    if (pinFailureCount.value == 3 && isBiometricRecoveryAvailable) {
      showRecoveryPrompt.value = true;
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

  // -------------------------------------------------------------------------
  // Biometric PIN recovery
  // -------------------------------------------------------------------------

  /// Forgot-PIN recovery flow. Triggered from the lock screen after the
  /// first lockout (3 fails). Runs a biometric prompt that bypasses the
  /// app's "biometric login enabled" toggle — device enrollment alone is
  /// proof of ownership for recovery. On success, clears rate-limit state,
  /// marks the home page to nudge a PIN reset, and navigates to /home.
  /// Returns true on successful biometric unlock, false otherwise.
  Future<bool> recoverWithBiometric() async {
    isLoading.value = true;
    try {
      final success = await _biometricService.authenticateForRecovery(
        localizedReason: 'biometricRecoveryReason'.tr(),
      );
      if (!success) {
        _flashAuthFailure();
        return false;
      }
      await _resetRateLimitState();
      recoveryPromptPending.value = true;
      authenticationSuccess.value = true;
      Get.offAllNamed('/home');
      return true;
    } on BiometricException catch (e) {
      Get.context?.showErrorSnackBar(e.message);
      _flashAuthFailure();
      return false;
    } catch (_) {
      Get.context?.showErrorSnackBar('biometricAuthError'.tr());
      _flashAuthFailure();
      return false;
    } finally {
      if (!authenticationSuccess.value) {
        isLoading.value = false;
      }
    }
  }

  /// Settings-side counterpart to [recoverWithBiometric]: verifies the user
  /// owns the device via biometric, but does not navigate or mark anything.
  /// The caller is responsible for pushing the PIN creation flow. Returns
  /// true if the user passed the biometric challenge.
  Future<bool> verifyBiometricForReset() async {
    try {
      return await _biometricService.authenticateForRecovery(
        localizedReason: 'biometricRecoveryReason'.tr(),
      );
    } on BiometricException catch (e) {
      Get.context?.showErrorSnackBar(e.message);
      return false;
    } catch (_) {
      Get.context?.showErrorSnackBar('biometricAuthError'.tr());
      return false;
    }
  }

  /// Read-once accessor for the post-recovery PIN reset nudge. The home
  /// page calls this in initState; subsequent reads return false so the
  /// prompt doesn't reappear after navigating away and back.
  bool consumeRecoveryPrompt() {
    if (!recoveryPromptPending.value) return false;
    recoveryPromptPending.value = false;
    return true;
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
