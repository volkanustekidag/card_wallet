import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wallet_app/core/data/storage/encrypted_box_opener.dart';
import 'package:wallet_app/core/services/error_reporter.dart';
import 'package:wallet_app/core/utils/secure_storage_provider.dart';

/// One-time "your cards stay on this device" notice, armed by
/// [EncryptedBoxOpener] when it had to replace a box whose key was gone
/// (typically the first launch after an iCloud restore to a new phone).
class DataResetNotice {
  DataResetNotice({FlutterSecureStorage? storage})
      : _storage = storage ?? SecureStorageProvider.instance;

  final FlutterSecureStorage _storage;

  /// True at most once: the flag is cleared before returning true. If it
  /// can't be cleared the notice is skipped and shown on a later launch
  /// rather than on every launch.
  Future<bool> consumePending() async {
    try {
      final pending =
          await _storage.read(key: EncryptedBoxOpener.dataResetNoticeKey);
      if (pending != 'true') return false;
      await _storage.delete(key: EncryptedBoxOpener.dataResetNoticeKey);
      return true;
    } catch (e, st) {
      ErrorReporter.report(e, st, reason: 'DataResetNotice.consume');
      return false;
    }
  }
}
