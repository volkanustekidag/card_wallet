import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pointycastle/export.dart' as pc;

import '../../constants/keys.dart';
import '../../domain/models/credit_card_model/credit_card.dart';
import '../../domain/models/iban_card_model/iban_card.dart';
import '../../domain/models/loyalty_card_model/loyalty_card.dart';

/// Errors surfaced by [BackupService]. The UI layer maps these to user-facing
/// localized strings.
enum BackupErrorKind {
  passwordRequired,
  wrongPassword,
  invalidFormat,
  io,
}

class BackupError implements Exception {
  final BackupErrorKind kind;
  final String message;
  BackupError(this.kind, this.message);

  @override
  String toString() => 'BackupError(${kind.name}): $message';
}

class BackupService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static const String _currentBackupVersion = '2.0';
  static const int _pbkdf2Iterations = 100000;
  static const int _keyLengthBytes = 32;
  static const int _saltLengthBytes = 16;
  static const int _ivLengthBytes = 16;

  Future<Box<CreditCard>> _getCreditCardsBox() async {
    if (Hive.isBoxOpen(C_CARD_BOX_NAME)) {
      return Hive.box<CreditCard>(C_CARD_BOX_NAME);
    }
    try {
      final secureKey =
          await _secureStorage.read(key: C_CARD_SECURE_STORAGE_KEY);
      if (secureKey != null) {
        final encryptionKey =
            (json.decode(secureKey) as List<dynamic>).cast<int>();
        return await Hive.openBox<CreditCard>(
          C_CARD_BOX_NAME,
          encryptionCipher: HiveAesCipher(encryptionKey),
        );
      }
    } catch (e) {
      debugPrint('Error opening credit cards box: $e');
    }
    return await Hive.openBox<CreditCard>(C_CARD_BOX_NAME);
  }

  Future<Box<LoyaltyCard>> _getLoyaltyCardsBox() async {
    if (Hive.isBoxOpen(LOYALTY_CARD_BOX_NAME)) {
      return Hive.box<LoyaltyCard>(LOYALTY_CARD_BOX_NAME);
    }
    try {
      final secureKey =
          await _secureStorage.read(key: LOYALTY_CARD_SECURE_STORAGE_KEY);
      if (secureKey != null) {
        final encryptionKey =
            (json.decode(secureKey) as List<dynamic>).cast<int>();
        return await Hive.openBox<LoyaltyCard>(
          LOYALTY_CARD_BOX_NAME,
          encryptionCipher: HiveAesCipher(encryptionKey),
        );
      }
    } catch (e) {
      debugPrint('Error opening loyalty cards box: $e');
    }
    return await Hive.openBox<LoyaltyCard>(LOYALTY_CARD_BOX_NAME);
  }

  Future<Box<IbanCard>> _getIbanCardsBox() async {
    if (Hive.isBoxOpen(I_CARD_BOX_NAME)) {
      return Hive.box<IbanCard>(I_CARD_BOX_NAME);
    }
    try {
      final secureKey =
          await _secureStorage.read(key: I_CARD_SECURE_STORAGE_KEY);
      if (secureKey != null) {
        final encryptionKey =
            (json.decode(secureKey) as List<dynamic>).cast<int>();
        return await Hive.openBox<IbanCard>(
          I_CARD_BOX_NAME,
          encryptionCipher: HiveAesCipher(encryptionKey),
        );
      }
    } catch (e) {
      debugPrint('Error opening IBAN cards box: $e');
    }
    return await Hive.openBox<IbanCard>(I_CARD_BOX_NAME);
  }

  Future<Map<String, dynamic>> _exportPlainData() async {
    final creditCardsBox = await _getCreditCardsBox();
    final ibanCardsBox = await _getIbanCardsBox();
    final loyaltyCardsBox = await _getLoyaltyCardsBox();

    final creditCards = <Map<String, dynamic>>[];
    for (var i = 0; i < creditCardsBox.length; i++) {
      final card = creditCardsBox.getAt(i);
      if (card == null) continue;
      // Note: cvc2 is intentionally omitted. Storing/exporting CVC is a
      // PCI-DSS violation; users will re-enter it on restore.
      creditCards.add({
        'id': card.id,
        'bankName': card.bankName,
        'creditCardNumber': card.creditCardNumber,
        'cardHolder': card.cardHolder,
        'expirationDate': card.expirationDate,
        'cardColorId': card.cardColorId,
        'createdAt': card.createdAt?.toIso8601String(),
      });
    }

    final ibanCards = <Map<String, dynamic>>[];
    for (var i = 0; i < ibanCardsBox.length; i++) {
      final card = ibanCardsBox.getAt(i);
      if (card == null) continue;
      ibanCards.add({
        'id': card.id,
        'bankName': card.bankName,
        'cardHolder': card.cardHolder,
        'iban': card.iban,
        'swiftCode': card.swiftCode,
        'createdAt': card.createdAt?.toIso8601String(),
      });
    }

    final loyaltyCards = <Map<String, dynamic>>[];
    for (var i = 0; i < loyaltyCardsBox.length; i++) {
      final card = loyaltyCardsBox.getAt(i);
      if (card == null) continue;
      loyaltyCards.add({
        'id': card.id,
        'name': card.name,
        'brand': card.brand,
        'barcode': card.barcode,
        'barcodeFormat': card.barcodeFormat,
        'colorId': card.colorId,
        'notes': card.notes,
        'createdAt': card.createdAt?.toIso8601String(),
        'logoAsset': card.logoAsset,
      });
    }

    return {
      'creditCards': creditCards,
      'ibanCards': ibanCards,
      'loyaltyCards': loyaltyCards,
    };
  }

  /// Creates an encrypted JSON backup file at the platform default location
  /// and returns its path. The data is encrypted with AES-256-CBC using a key
  /// derived from [password] via PBKDF2-HMAC-SHA256.
  Future<String> createBackupFile({required String password}) async {
    if (password.length < 6) {
      throw BackupError(
        BackupErrorKind.passwordRequired,
        'Password must be at least 6 characters.',
      );
    }
    try {
      await _requestStoragePermission();

      final plainData = await _exportPlainData();
      final plaintext = jsonEncode(plainData);

      final salt = _randomBytes(_saltLengthBytes);
      final iv = _randomBytes(_ivLengthBytes);
      final key = _deriveKey(password, salt);

      final encrypter = enc.Encrypter(
        enc.AES(enc.Key(key), mode: enc.AESMode.cbc, padding: 'PKCS7'),
      );
      final encrypted = encrypter.encrypt(plaintext, iv: enc.IV(iv));

      final envelope = <String, dynamic>{
        'version': _currentBackupVersion,
        'encrypted': true,
        'algorithm': 'AES-256-CBC',
        'kdf': 'PBKDF2-HMAC-SHA256',
        'iterations': _pbkdf2Iterations,
        'salt': base64Encode(salt),
        'iv': base64Encode(iv),
        'data': encrypted.base64,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final directory = await _resolveBackupDirectory();
      final fileName =
          'card_wallet_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonEncode(envelope));
      return file.path;
    } on BackupError {
      rethrow;
    } catch (e) {
      throw BackupError(
        BackupErrorKind.io,
        'Failed to create backup: $e',
      );
    }
  }

  Future<Directory> _resolveBackupDirectory() async {
    if (Platform.isAndroid) {
      final ext = await getExternalStorageDirectory();
      if (ext != null) {
        final downloads = Directory('${ext.path}/Download');
        if (!await downloads.exists()) {
          await downloads.create(recursive: true);
        }
        return downloads;
      }
    }
    return await getApplicationDocumentsDirectory();
  }

  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
    }
  }

  /// Picks a backup file and restores its contents. [passwordProvider] is
  /// invoked when the file is encrypted (v2.0+). Returns true on success.
  Future<void> restoreFromFile({
    required Future<String?> Function() passwordProvider,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        throw BackupError(BackupErrorKind.io, 'No file selected');
      }

      final file = File(result.files.single.path!);
      await restoreFromFileContent(file, passwordProvider: passwordProvider);
    } on BackupError {
      rethrow;
    } catch (e) {
      throw BackupError(BackupErrorKind.io, 'Restore failed: $e');
    }
  }

  Future<void> restoreFromFileContent(
    File file, {
    required Future<String?> Function() passwordProvider,
  }) async {
    final raw = await file.readAsString();
    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      throw BackupError(BackupErrorKind.invalidFormat, 'Invalid JSON');
    }

    if (!decoded.containsKey('version')) {
      throw BackupError(
        BackupErrorKind.invalidFormat,
        'Backup is missing version metadata',
      );
    }

    final version = decoded['version'].toString();
    Map<String, dynamic> data;

    if (version == '1.0') {
      // Legacy unencrypted format.
      final legacy = decoded['data'];
      if (legacy is! Map<String, dynamic>) {
        throw BackupError(BackupErrorKind.invalidFormat, 'Bad legacy data');
      }
      data = legacy;
    } else if (version.startsWith('2.')) {
      data = await _decryptV2(decoded, passwordProvider);
    } else {
      throw BackupError(
        BackupErrorKind.invalidFormat,
        'Unsupported backup version: $version',
      );
    }

    final creditCardsData = data['creditCards'];
    final ibanCardsData = data['ibanCards'];
    final loyaltyCardsData = data['loyaltyCards'] ?? const <dynamic>[];
    if (creditCardsData is! List || ibanCardsData is! List) {
      throw BackupError(
        BackupErrorKind.invalidFormat,
        'Backup payload missing card lists',
      );
    }
    if (loyaltyCardsData is! List) {
      throw BackupError(
        BackupErrorKind.invalidFormat,
        'Backup loyalty cards must be a list',
      );
    }

    await _atomicReplace(
      newCreditCards: creditCardsData,
      newIbanCards: ibanCardsData,
      newLoyaltyCards: loyaltyCardsData,
    );
  }

  Future<Map<String, dynamic>> _decryptV2(
    Map<String, dynamic> envelope,
    Future<String?> Function() passwordProvider,
  ) async {
    final encryptedFlag = envelope['encrypted'] == true;
    if (!encryptedFlag) {
      // Allow unencrypted v2 envelopes for forward-compat (not currently
      // produced by this app, but harmless).
      final inline = envelope['data'];
      if (inline is Map<String, dynamic>) return inline;
      throw BackupError(
        BackupErrorKind.invalidFormat,
        'Encrypted flag missing on v2 backup',
      );
    }

    final saltStr = envelope['salt'];
    final ivStr = envelope['iv'];
    final dataStr = envelope['data'];
    final iterations = (envelope['iterations'] as int?) ?? _pbkdf2Iterations;
    if (saltStr is! String || ivStr is! String || dataStr is! String) {
      throw BackupError(
        BackupErrorKind.invalidFormat,
        'Encrypted backup missing salt/iv/data',
      );
    }

    final password = await passwordProvider();
    if (password == null || password.isEmpty) {
      throw BackupError(
        BackupErrorKind.passwordRequired,
        'Password is required to restore this backup',
      );
    }

    final salt = base64Decode(saltStr);
    final iv = base64Decode(ivStr);
    final key = _deriveKey(password, salt, iterations: iterations);

    try {
      final encrypter = enc.Encrypter(
        enc.AES(enc.Key(key), mode: enc.AESMode.cbc, padding: 'PKCS7'),
      );
      final decrypted = encrypter.decrypt64(dataStr, iv: enc.IV(iv));
      return jsonDecode(decrypted) as Map<String, dynamic>;
    } catch (e) {
      throw BackupError(
        BackupErrorKind.wrongPassword,
        'Decryption failed (wrong password or corrupted file)',
      );
    }
  }

  Future<void> _atomicReplace({
    required List<dynamic> newCreditCards,
    required List<dynamic> newIbanCards,
    required List<dynamic> newLoyaltyCards,
  }) async {
    final creditCardsBox = await _getCreditCardsBox();
    final ibanCardsBox = await _getIbanCardsBox();
    final loyaltyCardsBox = await _getLoyaltyCardsBox();

    // Snapshot existing data before destruction so we can roll back on failure.
    final creditSnapshot = creditCardsBox.values.toList();
    final ibanSnapshot = ibanCardsBox.values.toList();
    final loyaltySnapshot = loyaltyCardsBox.values.toList();

    try {
      await creditCardsBox.clear();
      await ibanCardsBox.clear();
      await loyaltyCardsBox.clear();

      for (final raw in newCreditCards) {
        if (raw is! Map) continue;
        await creditCardsBox.add(
          CreditCard(
            id: raw['id'],
            bankName: (raw['bankName'] ?? '') as String,
            creditCardNumber: (raw['creditCardNumber'] ?? '') as String,
            cardHolder: (raw['cardHolder'] ?? '') as String,
            expirationDate: (raw['expirationDate'] ?? '') as String,
            // CVC is no longer stored in backups; users must re-enter it.
            cvc2: (raw['cvc2'] ?? '') as String,
            cardColorId: (raw['cardColorId'] as int?) ?? 0,
            createdAt: _parseDate(raw['createdAt']),
          ),
        );
      }

      for (final raw in newIbanCards) {
        if (raw is! Map) continue;
        await ibanCardsBox.add(
          IbanCard(
            id: raw['id'],
            bankName: (raw['bankName'] ?? '') as String,
            cardHolder: (raw['cardHolder'] ?? '') as String,
            iban: (raw['iban'] ?? '') as String,
            swiftCode: (raw['swiftCode'] ?? '') as String,
            createdAt: _parseDate(raw['createdAt']),
          ),
        );
      }

      for (final raw in newLoyaltyCards) {
        if (raw is! Map) continue;
        await loyaltyCardsBox.add(
          LoyaltyCard(
            id: (raw['id'] ?? '') as String,
            name: (raw['name'] ?? '') as String,
            brand: raw['brand'] as String?,
            barcode: (raw['barcode'] ?? '') as String,
            barcodeFormat: (raw['barcodeFormat'] ?? 'CODE_128') as String,
            colorId: (raw['colorId'] as int?) ?? 0,
            notes: raw['notes'] as String?,
            createdAt: _parseDate(raw['createdAt']),
            logoAsset: raw['logoAsset'] as String?,
          ),
        );
      }
    } catch (e) {
      // Roll back to the pre-restore snapshot so the user keeps their data.
      await creditCardsBox.clear();
      await ibanCardsBox.clear();
      await loyaltyCardsBox.clear();
      for (final card in creditSnapshot) {
        await creditCardsBox.add(card);
      }
      for (final card in ibanSnapshot) {
        await ibanCardsBox.add(card);
      }
      for (final card in loyaltySnapshot) {
        await loyaltyCardsBox.add(card);
      }
      throw BackupError(
        BackupErrorKind.io,
        'Restore aborted; previous data was kept: $e',
      );
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Future<void> clearAllData() async {
    final creditCardsBox = await _getCreditCardsBox();
    final ibanCardsBox = await _getIbanCardsBox();
    final loyaltyCardsBox = await _getLoyaltyCardsBox();
    await creditCardsBox.clear();
    await ibanCardsBox.clear();
    await loyaltyCardsBox.clear();
  }

  // PBKDF2-HMAC-SHA256
  static Uint8List _deriveKey(
    String password,
    List<int> salt, {
    int iterations = _pbkdf2Iterations,
  }) {
    final params = pc.Pbkdf2Parameters(
      Uint8List.fromList(salt),
      iterations,
      _keyLengthBytes,
    );
    final derivator = pc.PBKDF2KeyDerivator(
      pc.HMac(pc.SHA256Digest(), 64),
    )..init(params);
    return derivator.process(Uint8List.fromList(utf8.encode(password)));
  }

  static Uint8List _randomBytes(int length) {
    final rand = Random.secure();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = rand.nextInt(256);
    }
    return bytes;
  }
}
