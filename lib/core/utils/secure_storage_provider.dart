import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Single source of truth for [FlutterSecureStorage] configuration.
///
/// Without explicit options the plugin falls back to platform defaults that
/// don't bind the keychain entries to this device — meaning on iOS a backup
/// restore can carry PIN hashes and Hive encryption keys to a different
/// handset. `first_unlock_this_device` prevents that and also blocks access
/// while the device is locked.
///
/// On Android we opt into EncryptedSharedPreferences explicitly; the default
/// path is fine on modern Android but the explicit flag avoids any future
/// regression in the plugin's defaults.
class SecureStorageProvider {
  const SecureStorageProvider._();

  static const FlutterSecureStorage instance = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: false,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
}
