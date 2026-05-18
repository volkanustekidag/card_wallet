import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:wallet_app/core/constants/keys.dart';
import 'package:wallet_app/core/domain/models/verification_model/verification.dart';
import 'package:wallet_app/core/utils/pin_hasher.dart';
import 'package:wallet_app/core/utils/secure_storage_provider.dart';

class AuthenticationService {
  AuthenticationService._internal();
  static final AuthenticationService _instance =
      AuthenticationService._internal();
  factory AuthenticationService() => _instance;

  final FlutterSecureStorage _secureStorage = SecureStorageProvider.instance;
  Box<Verification>? _user;
  Future<void>? _openingFuture;

  Future<void> init() async {
    if (_user?.isOpen == true) return;

    if (_openingFuture != null) {
      await _openingFuture;
      return;
    }

    final completer = Completer<void>();
    _openingFuture = completer.future;

    try {
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(VerificationAdapter());
      }
      await _openEncryptedBox();
      completer.complete();
    } catch (e, stackTrace) {
      completer.completeError(e, stackTrace);
      rethrow;
    } finally {
      _openingFuture = null;
    }
  }

  Future<void> openBox() async {
    await _ensureBoxReady();
  }

  Future<Verification?> checkHavePassword() async {
    final box = await _ensureBoxReady();
    if (box.values.isNotEmpty) {
      return box.values.first;
    }
    return null;
  }

  /// Synchronous variant for callers that have already awaited [init] (e.g.
  /// the lock screen after main()). Used to render the correct initial UI
  /// without spinning the auth controller through an async round-trip.
  bool hasPasswordSync() {
    final box = _user;
    if (box == null || !box.isOpen) return false;
    return box.values.isNotEmpty;
  }

  /// Authenticates the entered [pin]. Returns true on match. Transparently
  /// migrates legacy plaintext PINs to a hashed form on first successful
  /// authentication.
  Future<bool?> authenticate(String pin) async {
    final box = await _ensureBoxReady();
    if (box.values.isEmpty) return null;
    final stored = box.values.first;
    final key = stored.key;

    final salt = stored.salt;
    if (salt == null || stored.isLegacyPin) {
      // Legacy v1 record: stored.password is the PIN in plaintext.
      final matches = stored.password == pin;
      if (matches) {
        await _writeHashedPin(box, key, pin);
      }
      return matches;
    }

    final candidate = await PinHasher.hash(pin, salt);
    return PinHasher.constantTimeEquals(candidate, stored.password);
  }

  /// Hashes [pin] with a fresh salt and persists it. Used for first-time PIN
  /// creation and for changing the PIN.
  Future<void> creatPassword(String pin) async {
    final box = await _ensureBoxReady();
    final salt = PinHasher.generateSalt();
    final hash = await PinHasher.hash(pin, salt);
    await box.put(
      1,
      Verification(hash, salt: salt, isLegacyPin: false),
    );
  }

  /// Replaces the existing PIN with [pin]. Mirrors [creatPassword] but is
  /// kept under the original name used by ChangePinController.
  Future<void> updatePin(String pin) async {
    final box = await _ensureBoxReady();
    final salt = PinHasher.generateSalt();
    final hash = await PinHasher.hash(pin, salt);
    await box.put(
      1,
      Verification(hash, salt: salt, isLegacyPin: false),
    );
  }

  /// Drops the stored PIN. Used by the settings "disable lock" flow after
  /// the user has verified their current PIN. The encrypted box itself is
  /// kept so we don't have to regenerate the encryption key — only the
  /// verification record is removed.
  Future<void> deletePassword() async {
    final box = await _ensureBoxReady();
    await box.delete(1);
  }

  Future<void> _writeHashedPin(
    Box<Verification> box,
    dynamic key,
    String pin,
  ) async {
    final salt = PinHasher.generateSalt();
    final hash = await PinHasher.hash(pin, salt);
    await box.put(
      key ?? 1,
      Verification(hash, salt: salt, isLegacyPin: false),
    );
  }

  Future<Box<Verification>> _ensureBoxReady() async {
    if (_user?.isOpen == true) {
      return _user!;
    }

    await init();
    if (_user == null) {
      throw StateError('Authentication box could not be opened');
    }
    return _user!;
  }

  Future<void> _openEncryptedBox() async {
    List<int> encryptionKey;
    final boxExists = await Hive.boxExists(LOGIN_BOX_NAME);

    if (!boxExists) {
      final secureKey = Hive.generateSecureKey();
      encryptionKey = secureKey;
      await _secureStorage.write(
        key: LOGIN_SECURE_STORAGE_KEY,
        value: json.encode(secureKey),
      );
    } else {
      final storedKey =
          await _secureStorage.read(key: LOGIN_SECURE_STORAGE_KEY);
      if (storedKey == null) {
        throw Exception('Missing encryption key for authentication storage');
      }
      encryptionKey = (json.decode(storedKey) as List<dynamic>).cast<int>();
    }

    _user = await Hive.openBox(
      LOGIN_BOX_NAME,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  }
}
