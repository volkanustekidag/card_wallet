import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:wallet_app/core/constants/keys.dart';
import 'package:wallet_app/core/domain/models/verification_model/verification.dart';

class AuthenticationService {
  Box? _user;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(VerificationAdapter());
    }

    bool boxExists = await Hive.boxExists(LOGIN_BOX_NAME);

    if (boxExists == false) {
      final secureKey = Hive.generateSecureKey();
      const secureStorage = FlutterSecureStorage();

      _user = await Hive.openBox(LOGIN_BOX_NAME,
          encryptionCipher: HiveAesCipher(secureKey));

      await secureStorage.write(
          key: LOGIN_SECURE_STORAGE_KEY, value: json.encode(secureKey));
    }
  }

  Future<void> openBox() async {
    final secureKey =
        await const FlutterSecureStorage().read(key: LOGIN_SECURE_STORAGE_KEY);

    List<int> encryptionKey =
        (json.decode(secureKey!) as List<dynamic>).cast<int>();

    _user = await Hive.openBox(
      LOGIN_BOX_NAME,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  }

  Future<Verification?> checkHavePassword() async {
    if (_user!.values.isNotEmpty) {
      return _user!.values.first;
    }
    return null;
  }

  Future<void> updatePin(final String pin) async {
    _user?.put(1, Verification(pin));
  }

  Future<bool?> authenticate(final password) async {
    final success = await _user?.values.first.password == password;
    return success;
  }

  Future<void> creatPassword(final String password) async {
    _user?.put(1, Verification(password));
  }
}
