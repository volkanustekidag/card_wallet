import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/utils/secure_storage_provider.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  static const _storage = SecureStorageProvider.instance;

  // Storage keys
  static const String _biometricEnabledKey = 'biometric_enabled';
  // Legacy minute-based value; migrated to [_autoLockSecondsKey] on read.
  static const String _legacyAutoLockMinutesKey = 'auto_lock_time';
  static const String _autoLockSecondsKey = 'auto_lock_seconds';
  // No longer written; still cleared so old installs don't keep it around.
  static const String _lastActiveTimeKey = 'last_active_time';

  static const int defaultAutoLockSeconds = 30;

  /// Check if biometric authentication is available on device
  Future<bool> isBiometricAvailable() async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting biometrics: $e');
      return [];
    }
  }

  /// Check if biometric is enabled in app settings
  Future<bool> isBiometricEnabled() async {
    try {
      final String? enabled = await _storage.read(key: _biometricEnabledKey);
      return enabled == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Enable or disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _storage.write(
          key: _biometricEnabledKey, value: enabled.toString());
    } catch (e) {
      throw Exception('${'biometricSettingsSaveError'.tr()}: $e');
    }
  }

  /// Authenticate using biometric
  Future<bool> authenticateWithBiometric({
    String? localizedReason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      // Check if biometric is available
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        throw BiometricException('biometricNotSupported'.tr());
      }

      // Check if biometric is enabled
      final bool isEnabled = await isBiometricEnabled();
      if (!isEnabled) {
        throw BiometricException('biometricNotEnabled'.tr());
      }

      // Perform authentication
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason ?? 'biometricAuthenticateReason'.tr(),
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true, // Only use biometric authentication
          sensitiveTransaction: false, // Don't require device credential fallback
        ),
      );


      return didAuthenticate;
    } on PlatformException catch (e) {
      throw BiometricException(_handlePlatformException(e));
    } catch (e) {
      throw BiometricException('${'biometricAuthError'.tr()}: $e');
    }
  }

  /// Biometric prompt that ignores the app-level "biometric enabled" toggle.
  /// Used by PIN recovery: the user forgot their PIN, so we accept device
  /// biometric enrollment as proof of ownership regardless of whether they
  /// previously turned biometric login on in the app's settings.
  Future<bool> authenticateForRecovery({String? localizedReason}) async {
    try {
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        throw BiometricException('biometricNotSupported'.tr());
      }
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason ?? 'biometricAuthenticateReason'.tr(),
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
          biometricOnly: true,
          sensitiveTransaction: false,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      throw BiometricException(_handlePlatformException(e));
    } catch (e) {
      throw BiometricException('${'biometricAuthError'.tr()}: $e');
    }
  }

  /// Persist the auto-lock delay. Must be one of [AutoLockTime.options].
  Future<void> setAutoLockSeconds(int seconds) async {
    try {
      await _storage.write(key: _autoLockSecondsKey, value: '$seconds');
    } catch (e) {
      throw Exception('${'autoLockTimeSaveError'.tr()}: $e');
    }
  }

  /// Auto-lock delay in seconds (0 = immediately). Migrates the old
  /// minute-based value the first time it is read.
  Future<int> getAutoLockSeconds() async {
    try {
      final stored = int.tryParse(
        await _storage.read(key: _autoLockSecondsKey) ?? '',
      );
      if (stored != null) return AutoLockTime.normalize(stored);

      final legacyMinutes = int.tryParse(
        await _storage.read(key: _legacyAutoLockMinutesKey) ?? '',
      );
      if (legacyMinutes == null) return defaultAutoLockSeconds;
      final migrated = AutoLockTime.normalize(legacyMinutes * 60);
      await _storage.write(key: _autoLockSecondsKey, value: '$migrated');
      await _storage.delete(key: _legacyAutoLockMinutesKey);
      return migrated;
    } catch (e) {
      return defaultAutoLockSeconds;
    }
  }

  /// Get biometric type display name
  String getBiometricTypeDisplayName(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) {
      return 'faceRecognition'.tr();
    } else if (types.contains(BiometricType.fingerprint)) {
      return 'fingerprint'.tr();
    } else if (types.contains(BiometricType.iris)) {
      return 'irisRecognition'.tr();
    } else if (types.contains(BiometricType.strong)) {
      return 'strongBiometric'.tr();
    } else if (types.contains(BiometricType.weak)) {
      return 'biometric'.tr();
    } else {
      return 'biometricAuthentication'.tr();
    }
  }

  /// Handle platform exception and return user-friendly message
  String _handlePlatformException(PlatformException e) {
    switch (e.code) {
      case 'NotAvailable':
        return 'biometricNotAvailable'.tr();
      case 'NotEnrolled':
        return 'biometricNotEnrolled'.tr();
      case 'LockedOut':
        return 'biometricLockedOut'.tr();
      case 'PermanentlyLockedOut':
        return 'biometricPermanentlyLockedOut'.tr();
      case 'UserCancel':
        return 'biometricUserCancel'.tr();
      case 'UserFallback':
        return 'biometricUserFallback'.tr();
      case 'SystemCancel':
        return 'biometricSystemCancel'.tr();
      case 'InvalidContext':
        return 'biometricInvalidContext'.tr();
      case 'NotSupported':
        return 'biometricOperationNotSupported'.tr();
      default:
        return '${'biometricUnknownError'.tr()}: ${e.message}';
    }
  }

  /// Clear all biometric settings
  Future<void> clearBiometricSettings() async {
    try {
      await _storage.delete(key: _biometricEnabledKey);
      await _storage.delete(key: _legacyAutoLockMinutesKey);
      await _storage.delete(key: _autoLockSecondsKey);
      await _storage.delete(key: _lastActiveTimeKey);
    } catch (e) {
      // Silent fail
    }
  }
}

/// Custom exception for biometric operations
class BiometricException implements Exception {
  final String message;
  BiometricException(this.message);

  @override
  String toString() => 'BiometricException: $message';
}

/// Auto-lock delay options shown in Settings › Security.
class AutoLockTime {
  static const List<int> options = [0, 30, 60, 300, 900]; // seconds

  /// Snaps any stored value to the closest option that is not longer than
  /// it, so a migrated "2 minutes" becomes "1 minute" rather than "5".
  static int normalize(int seconds) {
    var result = options.first;
    for (final option in options) {
      if (option <= seconds) result = option;
    }
    return result;
  }

  static String label(int seconds) {
    if (seconds <= 0) return 'autoLockImmediately'.tr();
    if (seconds < 60) return 'autoLockAfterSeconds'.tr(args: ['$seconds']);
    final minutes = seconds ~/ 60;
    if (minutes == 1) return 'autoLockAfterOneMinute'.tr();
    return 'autoLockAfterMinutes'.tr(args: ['$minutes']);
  }
}
