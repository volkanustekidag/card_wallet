import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../constants/keys.dart';
import '../../domain/models/credit_card_model/credit_card.dart';
import '../../domain/models/iban_card_model/iban_card.dart';
import '../../domain/models/loyalty_card_model/loyalty_card.dart';
import '../../services/app_lock_service.dart';
import '../../services/card_reminder_service.dart';
import '../../services/wallet_surfaces_sync.dart';
import '../local_services/card_services/credi_card/credit_card_service.dart';
import '../local_services/card_services/iban_card/iban_card_service.dart';
import '../local_services/card_services/loyalty_card/loyalty_card_service.dart';
import 'backup_crypto.dart';

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
  /// Backups are small JSON files; refuse anything that clearly isn't one
  /// before reading it into memory.
  static const int _maxBackupBytes = 10 * 1024 * 1024;

  // Boxes are opened through the card services so they always use the
  // encrypted cipher. There is deliberately no plain `Hive.openBox`
  // fallback: opening an encrypted box without its key would either fail
  // or create an empty unencrypted box and restore card data into it.
  Future<Box<CreditCard>> _getCreditCardsBox() async {
    await _openThroughService(CreditCardService().openBox, 'credit');
    return _openBoxOrThrow<CreditCard>(C_CARD_BOX_NAME);
  }

  Future<Box<LoyaltyCard>> _getLoyaltyCardsBox() async {
    await _openThroughService(LoyaltyCardService().openBox, 'loyalty');
    return _openBoxOrThrow<LoyaltyCard>(LOYALTY_CARD_BOX_NAME);
  }

  Future<Box<IbanCard>> _getIbanCardsBox() async {
    await _openThroughService(IbanCardService().openBox, 'IBAN');
    return _openBoxOrThrow<IbanCard>(I_CARD_BOX_NAME);
  }

  Future<void> _openThroughService(
    Future<void> Function() open,
    String label,
  ) async {
    try {
      await open();
    } catch (e) {
      throw BackupError(BackupErrorKind.io, 'Could not open $label box: $e');
    }
  }

  Box<T> _openBoxOrThrow<T>(String name) {
    if (!Hive.isBoxOpen(name)) {
      throw BackupError(BackupErrorKind.io, 'Box $name is not open');
    }
    return Hive.box<T>(name);
  }

  Future<Map<String, dynamic>> _exportPlainData() async {
    final creditCardsBox = await _getCreditCardsBox();
    final ibanCardsBox = await _getIbanCardsBox();
    final loyaltyCardsBox = await _getLoyaltyCardsBox();

    final creditCards = <Map<String, dynamic>>[];
    for (var i = 0; i < creditCardsBox.length; i++) {
      final card = creditCardsBox.getAt(i);
      if (card == null) continue;
      // Note: CVC is intentionally omitted. Storing/exporting CVC is a
      // PCI-DSS violation; users will re-enter it on restore.
      creditCards.add({
        'id': card.id,
        'bankName': card.bankName,
        'creditCardNumber': card.creditCardNumber,
        'cardHolder': card.cardHolder,
        'expirationDate': card.expirationDate,
        'cardColorId': card.cardColorId,
        'createdAt': card.createdAt?.toIso8601String(),
        'notes': card.notes,
        'tags': card.tags,
        'expiryReminderEnabled': card.expiryReminderEnabled,
        'expiryReminderDaysBefore': card.expiryReminderDaysBefore,
        'paymentReminderEnabled': card.paymentReminderEnabled,
        'paymentDueDay': card.paymentDueDay,
        'paymentReminderDaysBefore': card.paymentReminderDaysBefore,
        'reminderHour': card.reminderHour,
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
        'notes': card.notes,
        'tags': card.tags,
      });
    }

    final loyaltyCards = <Map<String, dynamic>>[];
    for (var i = 0; i < loyaltyCardsBox.length; i++) {
      final card = loyaltyCardsBox.getAt(i);
      if (card == null) continue;
      loyaltyCards.add(loyaltyCardToJson(card));
    }

    return {
      'creditCards': creditCards,
      'ibanCards': ibanCards,
      'loyaltyCards': loyaltyCards,
    };
  }

  /// Builds an encrypted JSON backup and lets the user choose where to save it
  /// via the native system file picker (Storage Access Framework on Android,
  /// UIDocumentPickerViewController on iOS). Returns the saved path, or null
  /// if the user cancelled. Data is encrypted with AES-256-GCM using a key
  /// derived from [password] via PBKDF2-HMAC-SHA256.
  Future<String?> createBackupFile({
    required String password,
    String? dialogTitle,
  }) async {
    if (password.length < 6) {
      throw BackupError(
        BackupErrorKind.passwordRequired,
        'Password must be at least 6 characters.',
      );
    }
    try {
      final plainData = await _exportPlainData();
      final plaintext = jsonEncode(plainData);

      // PBKDF2 (100k rounds) + AES off the UI thread.
      final envelope = await compute(
        encryptBackupPayload,
        BackupEncryptRequest(
          plaintext: plaintext,
          password: password,
          timestamp: DateTime.now(),
        ),
      );

      final bytes =
          Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
      final fileName =
          'card_wallet_backup_${DateTime.now().millisecondsSinceEpoch}.json';

      return await AppLockService.guard(() => FilePicker.platform.saveFile(
        dialogTitle: dialogTitle,
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: bytes,
      ));
    } on BackupError {
      rethrow;
    } catch (e) {
      throw BackupError(
        BackupErrorKind.io,
        'Failed to create backup: $e',
      );
    }
  }

  /// Picks a backup file and restores its contents. [passwordProvider] is
  /// invoked when the file is encrypted (v2.0+). [confirmLegacyPlaintext] is
  /// asked before restoring an unencrypted v1.0 backup.
  ///
  /// Returns false when the user cancels (file picker, password prompt or
  /// the plaintext warning), true after a successful restore.
  Future<bool> restoreFromFile({
    required Future<String?> Function() passwordProvider,
    required Future<bool> Function() confirmLegacyPlaintext,
  }) async {
    final String raw;
    try {
      // FileType.any: Android file managers often report .json backups as
      // application/octet-stream, which a ['json'] filter greys out. The
      // content is validated below instead.
      final result = await AppLockService.guard(
        () => FilePicker.platform.pickFiles(type: FileType.any),
      );
      final path = result?.files.single.path;
      if (path == null) return false;

      final file = File(path);
      if (await file.length() > _maxBackupBytes) {
        throw BackupError(BackupErrorKind.invalidFormat, 'File too large');
      }
      raw = await file.readAsString();
    } on BackupError {
      rethrow;
    } on FileSystemException catch (e) {
      throw BackupError(BackupErrorKind.io, 'Could not read file: $e');
    } catch (e) {
      // readAsString throws on binary (non UTF-8) files: not a backup.
      throw BackupError(BackupErrorKind.invalidFormat, 'Not a backup: $e');
    }

    final data = await decodeBackup(
      raw,
      passwordProvider: passwordProvider,
      confirmLegacyPlaintext: confirmLegacyPlaintext,
    );
    if (data == null) return false;
    await _restorePayload(data);
    return true;
  }

  /// Validates and decodes a backup file's text into the card payload.
  /// Returns null if the user declined the plaintext (v1.0) warning.
  @visibleForTesting
  static Future<Map<String, dynamic>?> decodeBackup(
    String raw, {
    required Future<String?> Function() passwordProvider,
    required Future<bool> Function() confirmLegacyPlaintext,
  }) async {
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
    final Map<String, dynamic> data;

    if (version == '1.0') {
      // Legacy unencrypted format.
      final legacy = decoded['data'];
      if (legacy is! Map<String, dynamic>) {
        throw BackupError(BackupErrorKind.invalidFormat, 'Bad legacy data');
      }
      if (!await confirmLegacyPlaintext()) return null;
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
    return data;
  }

  Future<void> _restorePayload(Map<String, dynamic> data) async {
    await _atomicReplace(
      newCreditCards: data['creditCards'] as List,
      newIbanCards: data['ibanCards'] as List,
      newLoyaltyCards: (data['loyaltyCards'] as List?) ?? const <dynamic>[],
    );
    // Widget, quick tile and Watch should show the restored cards now, not
    // after the debounce.
    await WalletSurfacesSync.instance.syncNow();
  }

  static Future<Map<String, dynamic>> _decryptV2(
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
    if (envelope['salt'] is! String || envelope['data'] is! String) {
      throw BackupError(
        BackupErrorKind.invalidFormat,
        'Encrypted backup missing salt/data',
      );
    }

    final password = await passwordProvider();
    if (password == null || password.isEmpty) {
      throw BackupError(
        BackupErrorKind.passwordRequired,
        'Password is required to restore this backup',
      );
    }

    try {
      return await compute(
        decryptBackupPayload,
        BackupDecryptRequest(envelope: envelope, password: password),
      );
    } on BackupCryptoException catch (e) {
      throw BackupError(
        e.wrongPassword
            ? BackupErrorKind.wrongPassword
            : BackupErrorKind.invalidFormat,
        e.message,
      );
    }
  }

  Future<void> _atomicReplace({
    required List<dynamic> newCreditCards,
    required List<dynamic> newIbanCards,
    required List<dynamic> newLoyaltyCards,
  }) async {
    // Parse everything into model objects *before* touching any box. If a row
    // is malformed enough to throw, we abort here and the user's existing
    // data is untouched — no clear() has run yet.
    final List<CreditCard> parsedCredit;
    final List<IbanCard> parsedIban;
    final List<LoyaltyCard> parsedLoyalty;
    try {
      parsedCredit = [
        for (final raw in newCreditCards)
          if (raw is Map) _buildCreditCard(raw),
      ];
      parsedIban = [
        for (final raw in newIbanCards)
          if (raw is Map) _buildIbanCard(raw),
      ];
      parsedLoyalty = [
        for (final raw in newLoyaltyCards)
          if (raw is Map) _buildLoyaltyCard(raw),
      ];
    } catch (e) {
      throw BackupError(
        BackupErrorKind.invalidFormat,
        'Backup contains malformed card entries: $e',
      );
    }

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

      for (final card in parsedCredit) {
        await creditCardsBox.add(card);
      }
      for (final card in parsedIban) {
        await ibanCardsBox.add(card);
      }
      for (final card in parsedLoyalty) {
        await loyaltyCardsBox.add(card);
      }
    } catch (e) {
      // Roll back to the pre-restore snapshot so the user keeps their data.
      // The rollback itself can fail (disk full, box closed, etc.) — guard it
      // so we surface a distinct error instead of leaking the rollback error
      // and hiding the original cause.
      try {
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
      } catch (rollbackError) {
        throw BackupError(
          BackupErrorKind.io,
          'Restore failed and rollback also failed; data may be inconsistent. '
          'Original error: $e. Rollback error: $rollbackError',
        );
      }
      await CardReminderService.guarded(
        'restoreRollbackReminders',
        () => CardReminderService().scheduleAllCreditCardReminders(
          creditSnapshot,
        ),
      );
      throw BackupError(
        BackupErrorKind.io,
        'Restore aborted; previous data was kept: $e',
      );
    }

    // Outside the try: the cards are already written, so a notification
    // failure must not roll the restore back.
    await CardReminderService.guarded(
      'restoreReminders',
      () => CardReminderService().scheduleAllCreditCardReminders(
        creditCardsBox.values.toList(),
      ),
    );
  }

  CreditCard _buildCreditCard(Map raw) {
    return CreditCard(
      id: raw['id'],
      bankName: (raw['bankName'] ?? '') as String,
      creditCardNumber: (raw['creditCardNumber'] ?? '') as String,
      cardHolder: (raw['cardHolder'] ?? '') as String,
      expirationDate: (raw['expirationDate'] ?? '') as String,
      cardColorId: (raw['cardColorId'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(raw['createdAt']),
      notes: raw['notes'] as String?,
      tags: _parseStringList(raw['tags']),
      expiryReminderEnabled: (raw['expiryReminderEnabled'] as bool?) ?? false,
      expiryReminderDaysBefore:
          (raw['expiryReminderDaysBefore'] as num?)?.toInt() ?? 30,
      paymentReminderEnabled:
          (raw['paymentReminderEnabled'] as bool?) ?? false,
      paymentDueDay: (raw['paymentDueDay'] as num?)?.toInt(),
      paymentReminderDaysBefore:
          (raw['paymentReminderDaysBefore'] as num?)?.toInt() ?? 3,
      reminderHour: (raw['reminderHour'] as num?)?.toInt() ?? 9,
    );
  }

  IbanCard _buildIbanCard(Map raw) {
    return IbanCard(
      id: raw['id'],
      bankName: (raw['bankName'] ?? '') as String,
      cardHolder: (raw['cardHolder'] ?? '') as String,
      iban: (raw['iban'] ?? '') as String,
      swiftCode: (raw['swiftCode'] ?? '') as String,
      createdAt: _parseDate(raw['createdAt']),
      notes: raw['notes'] as String?,
      tags: _parseStringList(raw['tags']),
    );
  }

  LoyaltyCard _buildLoyaltyCard(Map raw) => loyaltyCardFromJson(raw);

  /// Backup shape of a loyalty card. `lastUsedAt` / `useCount` (2.2+) feed
  /// the usage ordering.
  static Map<String, dynamic> loyaltyCardToJson(LoyaltyCard card) => {
        'id': card.id,
        'name': card.name,
        'brand': card.brand,
        'barcode': card.barcode,
        'barcodeFormat': card.barcodeFormat,
        'colorId': card.colorId,
        'notes': card.notes,
        'createdAt': card.createdAt?.toIso8601String(),
        'logoAsset': card.logoAsset,
        'tags': card.tags,
        'website': card.website,
        'lastUsedAt': card.lastUsedAt?.toIso8601String(),
        'useCount': card.useCount,
      };

  /// Inverse of [loyaltyCardToJson]. Backups from before 2.2 have no usage
  /// fields; they restore as null (never used).
  static LoyaltyCard loyaltyCardFromJson(Map raw) {
    return LoyaltyCard(
      id: (raw['id'] ?? '') as String,
      name: (raw['name'] ?? '') as String,
      brand: raw['brand'] as String?,
      barcode: (raw['barcode'] ?? '') as String,
      barcodeFormat: (raw['barcodeFormat'] ?? 'CODE_128') as String,
      colorId: (raw['colorId'] as num?)?.toInt() ?? 0,
      notes: raw['notes'] as String?,
      createdAt: _parseDate(raw['createdAt']),
      logoAsset: raw['logoAsset'] as String?,
      tags: _parseStringList(raw['tags']),
      website: raw['website'] as String?,
      lastUsedAt: _parseDate(raw['lastUsedAt']),
      useCount: (raw['useCount'] as num?)?.toInt(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static List<String>? _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return null;
  }
}
