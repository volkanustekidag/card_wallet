import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:wallet_app/core/services/error_reporter.dart';
import 'package:wallet_app/core/utils/secure_storage_provider.dart';

/// The Keychain / Keystore could not be read or written right now (device
/// locked before first unlock, keystore glitch, …). Transient by nature:
/// the data on disk is intact and must be left alone.
class StorageUnavailableException implements Exception {
  final String boxName;
  final Object cause;

  StorageUnavailableException(this.boxName, this.cause);

  @override
  String toString() => 'StorageUnavailableException($boxName): $cause';
}

/// Raised (and only reported, never thrown) when a box file exists but its
/// encryption key is gone — the box can never be decrypted again.
class OrphanBoxException implements Exception {
  final String boxName;

  OrphanBoxException(this.boxName);

  @override
  String toString() => 'OrphanBoxException($boxName)';
}

typedef ErrorReport = void Function(
  Object error,
  StackTrace? stack, {
  String? reason,
});

/// Opens an AES-encrypted Hive box whose key lives in secure storage. Every
/// encrypted box (auth, credit, IBAN, loyalty — and migrations touching
/// them) goes through here so the "box without key" cases are handled once.
///
/// * No box on disk → fresh key, new box (first install / reinstall).
/// * Box + key → open with the stored key.
/// * Box but the key is *absent* → orphan box. Happens when an iCloud /
///   iTunes backup restores the Hive files to a new phone: the keys are
///   `first_unlock_this_device` and stay behind. The box is undecryptable,
///   so it's deleted and replaced with an empty one, and
///   [dataResetNoticeKey] tells home to explain what happened.
/// * Secure storage *throws* → never delete anything. One retry after
///   [retryDelay], then [StorageUnavailableException].
class EncryptedBoxOpener {
  EncryptedBoxOpener({
    FlutterSecureStorage? storage,
    this.retryDelay = const Duration(milliseconds: 300),
    ErrorReport? report,
  })  : _storage = storage ?? SecureStorageProvider.instance,
        _report = report ?? ErrorReporter.report;

  /// Set when an orphan box was replaced; home shows a one-time notice and
  /// deletes it.
  static const String dataResetNoticeKey = 'data_reset_notice_pending';

  final FlutterSecureStorage _storage;
  final Duration retryDelay;
  final ErrorReport _report;

  Future<Box<T>> open<T>({
    required String boxName,
    required String keyName,
  }) async {
    if (!await Hive.boxExists(boxName)) {
      return _createFresh<T>(boxName, keyName);
    }

    final storedKey = await _withRetry(
      boxName,
      () => _storage.read(key: keyName),
    );
    if (storedKey == null) {
      return _replaceOrphan<T>(boxName, keyName);
    }

    final encryptionKey = (json.decode(storedKey) as List<dynamic>).cast<int>();
    return Hive.openBox<T>(
      boxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  }

  Future<Box<T>> _createFresh<T>(String boxName, String keyName) async {
    final key = Hive.generateSecureKey();
    await _withRetry(
      boxName,
      () => _storage.write(key: keyName, value: json.encode(key)),
    );
    return Hive.openBox<T>(boxName, encryptionCipher: HiveAesCipher(key));
  }

  Future<Box<T>> _replaceOrphan<T>(String boxName, String keyName) async {
    _report(
      OrphanBoxException(boxName),
      StackTrace.current,
      reason: 'orphan_box_$boxName',
    );
    // Flag and new key are written before the file goes: if secure storage
    // fails here we bail out with the (undecryptable) file still on disk
    // and retry next launch, rather than losing the notice.
    await _withRetry(
      boxName,
      () => _storage.write(key: dataResetNoticeKey, value: 'true'),
    );
    final key = Hive.generateSecureKey();
    await _withRetry(
      boxName,
      () => _storage.write(key: keyName, value: json.encode(key)),
    );
    await Hive.deleteBoxFromDisk(boxName);
    return Hive.openBox<T>(boxName, encryptionCipher: HiveAesCipher(key));
  }

  Future<R> _withRetry<R>(String boxName, Future<R> Function() action) async {
    try {
      return await action();
    } catch (_) {
      await Future<void>.delayed(retryDelay);
      try {
        return await action();
      } catch (e) {
        throw StorageUnavailableException(boxName, e);
      }
    }
  }
}
