import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/domain/models/verification_model/verification.dart';
import 'package:wallet_app/core/utils/secure_storage_provider.dart';

/// Hive schema migration runner.
///
/// ## Why this exists
///
/// Hive's binary format encodes records by field *index*. Adding a new
/// nullable field at the next index is safe — old records read back with
/// null. Anything else (renaming a field, changing a field's type, removing
/// a field, repurposing a `typeId`) silently corrupts old records: Hive
/// will either throw on `box.values`, or worse, hand the app garbage values
/// it then re-encrypts into the box. The blast radius is "user opens v2.1
/// and all their cards are gone", which manifests as a one-star review and
/// an uninstall.
///
/// Without a migration runner the only options are to never change the
/// schema, or to silently lose data. This runner lets us bump the schema
/// version *and* transform old records before the rest of the app reads
/// them.
///
/// ## How to ship a migration (v2.1 and beyond)
///
/// 1. Make the model change.
/// 2. Bump [_currentSchemaVersion] by one.
/// 3. Add an entry to [_migrations] keyed by the new version, returning a
///    `Future<void>` that performs the data transform.
/// 4. Inside the migration: open the affected box yourself with the same
///    encryption-key flow the services use — read the AES key from
///    [SecureStorageProvider] under the box's secure storage key, json
///    decode it, pass to `HiveAesCipher`. Iterate records, transform,
///    `put` back, then `close()` the box so services re-open it cleanly.
///    Guard with `Hive.boxExists(name)` so fresh installs short-circuit.
/// 5. For renames: read the old field via a temporary adapter / fallback,
///    write the new field, leave the old field's index unused going
///    forward (or null it out for clarity). Don't try to "remove" a Hive
///    field — just stop reading it.
///
/// ## What the runner guarantees
///
/// * **Single flight**: concurrent callers share the same Future. Safe to
///   await from multiple service `init()` methods if we ever wire it that
///   way; currently it's awaited once from `main()` before services boot.
/// * **Adapter registration**: all four model adapters are registered
///   before any migration runs. Services calling `Hive.registerAdapter`
///   later are no-ops (guarded by `isAdapterRegistered`).
/// * **Bookkeeping**: the on-disk version is only bumped after every
///   pending migration succeeds. A partial failure leaves the version
///   unchanged so the user retries the same step on next launch.
/// * **First boot**: existing users (no stored version) are marked at the
///   current version *without* running any migrations — their data is
///   already at the latest shipped schema. Fresh installs hit the same
///   path: empty boxes, marked current.
/// * **Crash reporting**: migration failures are reported to Crashlytics
///   as non-fatal and rethrown so `runZonedGuarded` in main.dart can pick
///   them up. The app continues to boot — refusing to start is worse UX
///   than running with old data.
class HiveMigrationRunner {
  HiveMigrationRunner._();

  /// Bump this every time the on-disk schema changes. The runner walks
  /// from the stored version + 1 up to this number, invoking each entry
  /// in [_migrations] in order.
  ///
  /// **v1**: initial shipped schema (CreditCard / IbanCard / LoyaltyCard /
  /// Verification as of release v2.0.0+30). No migrations needed to reach
  /// this state — fresh installs and existing users are both stamped at 1
  /// on first run of the runner.
  static const int _currentSchemaVersion = 1;

  /// Stored under [SecureStorageProvider]. Plain integer encoded as a
  /// string so we can read it with the same API as every other meta key
  /// (`onboarding_seen`, `pin_prompt_dismissed`, `widget_setup_seen`).
  static const String _versionKey = 'hive_schema_version';

  /// Add one entry per future schema version. Keys are the *target*
  /// version (i.e. the version the box will be at *after* the migration
  /// runs). Currently empty — v1 is the initial state.
  ///
  /// Example for a future v2:
  /// ```dart
  /// static final Map<int, Future<void> Function()> _migrations = {
  ///   2: _migrateV1ToV2,
  /// };
  /// ```
  static final Map<int, Future<void> Function()> _migrations = {};

  static Completer<void>? _completer;

  /// Idempotent: subsequent calls return the same Future until completion.
  /// On error the completer is cleared so the next boot can retry — this
  /// matters when an error is transient (Keychain locked, disk full).
  static Future<void> runIfNeeded() {
    final existing = _completer;
    if (existing != null) return existing.future;
    final completer = Completer<void>();
    _completer = completer;
    () async {
      try {
        await _run();
        completer.complete();
      } catch (e, s) {
        completer.completeError(e, s);
        _completer = null;
      }
    }();
    return completer.future;
  }

  static Future<void> _run() async {
    final stored = await _readStoredVersion();

    // First boot of any kind (fresh install OR existing user upgrading to
    // the build that introduced this runner). No data transform — just
    // mark the current line so future schema bumps know where to start.
    if (stored == null) {
      await _writeStoredVersion(_currentSchemaVersion);
      return;
    }

    // Already at or past current — common case on every launch after the
    // first. No-op.
    if (stored >= _currentSchemaVersion) return;

    // Downgrade (user installed a newer build, then sideloaded an older
    // one). We don't have rollback migrations and silently nuking newer
    // data would be worse than no-op — leave the stored version alone and
    // log so we notice the situation in Crashlytics.
    if (stored > _currentSchemaVersion) {
      debugPrint(
        '[HiveMigration] stored=$stored > current=$_currentSchemaVersion; '
        'refusing to downgrade.',
      );
      return;
    }

    // From here on we know a real migration is needed. Register adapters
    // up front so migration functions can open typed boxes.
    _registerAdaptersOnce();

    for (var v = stored + 1; v <= _currentSchemaVersion; v++) {
      final step = _migrations[v];
      if (step == null) {
        // The version constant says v is reachable but there's no code to
        // get there — programmer error. Refuse to bump the stored version
        // so we don't paper over the bug.
        throw StateError(
          'HiveMigrationRunner: no migration registered for target '
          'schema version $v. Update _migrations in '
          'lib/core/data/migration/hive_migration_runner.dart.',
        );
      }
      try {
        await step();
      } catch (e, s) {
        await _reportMigrationFailure(targetVersion: v, error: e, stack: s);
        rethrow;
      }
    }

    await _writeStoredVersion(_currentSchemaVersion);
  }

  static void _registerAdaptersOnce() {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(VerificationAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(IbanCardAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(CreditCardAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(LoyaltyCardAdapter());
    }
  }

  static Future<int?> _readStoredVersion() async {
    try {
      final raw =
          await SecureStorageProvider.instance.read(key: _versionKey);
      if (raw == null) return null;
      return int.tryParse(raw);
    } catch (_) {
      // Keychain unavailable. Pretend we have no version — the runner's
      // first-boot branch will try to write one. If the write also fails
      // we silently no-op and try again next launch.
      return null;
    }
  }

  static Future<void> _writeStoredVersion(int version) async {
    try {
      await SecureStorageProvider.instance.write(
        key: _versionKey,
        value: version.toString(),
      );
    } catch (_) {
      // Best-effort. Worst case: runner re-evaluates next launch and
      // re-runs idempotent migrations (which is why each migration should
      // be written to be safe to re-run).
    }
  }

  static Future<void> _reportMigrationFailure({
    required int targetVersion,
    required Object error,
    required StackTrace stack,
  }) async {
    debugPrint(
      '[HiveMigration] failed migrating to v$targetVersion: $error\n$stack',
    );
    if (kDebugMode) return;
    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: 'HiveMigrationRunner: target v$targetVersion',
        fatal: false,
      );
    } catch (_) {
      // Crashlytics SDK not initialized yet (shouldn't happen — main.dart
      // initializes it before us) or offline. Swallow.
    }
  }

}
