import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wallet_app/core/services/error_reporter.dart';

/// Keeps the Hive files out of iCloud / iTunes backups on iOS.
///
/// Their AES keys are `first_unlock_this_device` Keychain items and never
/// leave the phone, so a backup that restores the box files to a new device
/// only restores undecryptable data. Hive lives directly in Documents
/// (`Hive.initFlutter()` without a sub-directory); the native side flags
/// that directory and every `.hive` / `.lock` file in it with
/// `NSURLIsExcludedFromBackupKey`. Idempotent — run on every launch so
/// boxes created since the last launch are covered too.
///
/// Android needs nothing: `allowBackup="false"`.
class HiveBackupExclusion {
  const HiveBackupExclusion._();

  static const MethodChannel channel =
      MethodChannel('app.cardwallet/backup_exclusion');

  static Future<void> apply({
    Future<Directory> Function() hiveDirectory =
        getApplicationDocumentsDirectory,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      final dir = await hiveDirectory();
      await channel.invokeMethod<bool>('excludeFromBackup', {'path': dir.path});
    } catch (e, st) {
      ErrorReporter.report(e, st, reason: 'HiveBackupExclusion');
    }
  }
}
