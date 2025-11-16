import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:wallet_app/core/constants/keys.dart';
import 'package:wallet_app/core/domain/models/verification_model/verification.dart';

class AuthenticationService {
  AuthenticationService._internal();
  static final AuthenticationService _instance =
      AuthenticationService._internal();
  factory AuthenticationService() => _instance;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
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

  Future<void> updatePin(final String pin) async {
    final box = await _ensureBoxReady();
    await box.put(1, Verification(pin));
  }

  Future<bool?> authenticate(final String password) async {
    final box = await _ensureBoxReady();
    if (box.values.isEmpty) return null;
    return box.values.first.password == password;
  }

  Future<void> creatPassword(final String password) async {
    final box = await _ensureBoxReady();
    await box.put(1, Verification(password));
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
