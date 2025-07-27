import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:easy_localization/easy_localization.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  static const _storage = FlutterSecureStorage();

  // Storage keys
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _autoLockTimeKey = 'auto_lock_time';
  static const String _lastActiveTimeKey = 'last_active_time';

  /// Check if biometric authentication is available on device
  Future<bool> isBiometricAvailable() async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      print('Can check biometrics: $isAvailable');
      print('Device supported: $isDeviceSupported');
      return isAvailable && isDeviceSupported;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final biometrics = await _localAuth.getAvailableBiometrics();
      print('Raw biometrics from device: $biometrics');
      return biometrics;
    } catch (e) {
      print('Error getting biometrics: $e');
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
          biometricOnly: false, // Allow all available authentication methods
        ),
      );

      if (didAuthenticate) {
        await updateLastActiveTime();
      }

      return didAuthenticate;
    } on PlatformException catch (e) {
      throw BiometricException(_handlePlatformException(e));
    } catch (e) {
      throw BiometricException('${'biometricAuthError'.tr()}: $e');
    }
  }

  /// Set auto-lock timer (in minutes)
  Future<void> setAutoLockTime(int minutes) async {
    try {
      await _storage.write(key: _autoLockTimeKey, value: minutes.toString());
    } catch (e) {
      throw Exception('${'autoLockTimeSaveError'.tr()}: $e');
    }
  }

  /// Get auto-lock timer (in minutes)
  Future<int> getAutoLockTime() async {
    try {
      final String? time = await _storage.read(key: _autoLockTimeKey);
      return int.tryParse(time ?? '5') ?? 5; // Default 5 minutes
    } catch (e) {
      return 5;
    }
  }

  /// Update last active time
  Future<void> updateLastActiveTime() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch.toString();
      await _storage.write(key: _lastActiveTimeKey, value: now);
    } catch (e) {
      // Silent fail - not critical
    }
  }

  /// Check if app should be locked based on auto-lock timer
  Future<bool> shouldLockApp() async {
    try {
      final String? lastActiveStr =
          await _storage.read(key: _lastActiveTimeKey);
      if (lastActiveStr == null) return true;

      final int lastActive = int.tryParse(lastActiveStr) ?? 0;
      final int autoLockMinutes = await getAutoLockTime();
      final int autoLockMs = autoLockMinutes * 60 * 1000;

      final int now = DateTime.now().millisecondsSinceEpoch;
      final int timeDiff = now - lastActive;

      return timeDiff > autoLockMs;
    } catch (e) {
      return true; // Default to locked if error
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
      await _storage.delete(key: _autoLockTimeKey);
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

/// Auto-lock time options
class AutoLockTime {
  static const List<int> options = [1, 2, 5, 10, 15, 30]; // minutes

  static String getDisplayText(int minutes) {
    if (minutes == 1) return 'oneMinute'.tr();
    return '$minutes ${'minutes'.tr()}';
  }
}
