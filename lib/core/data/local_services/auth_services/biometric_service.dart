import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
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
      await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
    } catch (e) {
      throw Exception('Biometric ayarı kaydedilemedi: $e');
    }
  }

  /// Authenticate using biometric
  Future<bool> authenticateWithBiometric({
    String localizedReason = 'Uygulamaya erişmek için kimlik doğrulaması yapın',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      // Check if biometric is available
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        throw BiometricException('Biometric doğrulama cihazda desteklenmiyor');
      }

      // Check if biometric is enabled
      final bool isEnabled = await isBiometricEnabled();
      if (!isEnabled) {
        throw BiometricException('Biometric doğrulama etkinleştirilmemiş');
      }

      // Perform authentication
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        await updateLastActiveTime();
      }

      return didAuthenticate;
    } on PlatformException catch (e) {
      throw BiometricException(_handlePlatformException(e));
    } catch (e) {
      throw BiometricException('Biometric doğrulama hatası: $e');
    }
  }

  /// Set auto-lock timer (in minutes)
  Future<void> setAutoLockTime(int minutes) async {
    try {
      await _storage.write(key: _autoLockTimeKey, value: minutes.toString());
    } catch (e) {
      throw Exception('Otomatik kilit süresi kaydedilemedi: $e');
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
      final String? lastActiveStr = await _storage.read(key: _lastActiveTimeKey);
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
      return 'Yüz Tanıma';
    } else if (types.contains(BiometricType.fingerprint)) {
      return 'Parmak İzi';
    } else if (types.contains(BiometricType.iris)) {
      return 'Iris Tanıma';
    } else if (types.contains(BiometricType.strong)) {
      return 'Güçlü Biometric';
    } else if (types.contains(BiometricType.weak)) {
      return 'Biometric';
    } else {
      return 'Biometric Doğrulama';
    }
  }

  /// Handle platform exception and return user-friendly message
  String _handlePlatformException(PlatformException e) {
    switch (e.code) {
      case 'NotAvailable':
        return 'Biometric doğrulama bu cihazda mevcut değil';
      case 'NotEnrolled':
        return 'Cihazınızda kayıtlı biometric bilgi bulunamadı';
      case 'LockedOut':
        return 'Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin';
      case 'PermanentlyLockedOut':
        return 'Biometric doğrulama kalıcı olarak kilitlendi';
      case 'UserCancel':
        return 'Kullanıcı tarafından iptal edildi';
      case 'UserFallback':
        return 'Kullanıcı alternatif yöntem seçti';
      case 'SystemCancel':
        return 'Sistem tarafından iptal edildi';
      case 'InvalidContext':
        return 'Geçersiz bağlam';
      case 'NotSupported':
        return 'Bu işlem desteklenmiyor';
      default:
        return 'Bilinmeyen hata: ${e.message}';
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
    if (minutes == 1) return '1 dakika';
    return '$minutes dakika';
  }
}