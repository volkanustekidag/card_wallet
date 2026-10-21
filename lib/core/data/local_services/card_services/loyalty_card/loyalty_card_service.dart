import 'dart:async';

import 'package:hive/hive.dart';
import 'package:wallet_app/core/constants/keys.dart';
import 'package:wallet_app/core/data/storage/encrypted_box_opener.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/services/error_reporter.dart';
import 'package:wallet_app/core/utils/loyalty_usage.dart';

class LoyaltyCardService {
  LoyaltyCardService._internal();
  static final LoyaltyCardService _instance = LoyaltyCardService._internal();
  factory LoyaltyCardService() => _instance;

  final EncryptedBoxOpener _opener = EncryptedBoxOpener();
  Box<LoyaltyCard>? _box;
  Future<void>? _openingFuture;

  Future<void> init() async {
    if (_box?.isOpen == true) return;

    if (_openingFuture != null) {
      await _openingFuture;
      return;
    }

    final completer = Completer<void>();
    _openingFuture = completer.future;
    // The first caller gets the error via rethrow; without a listener the
    // completer's copy would also surface as an unhandled zone error.
    completer.future.ignore();

    try {
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(LoyaltyCardAdapter());
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

  Future<Stream<BoxEvent>> watch() async {
    final box = await _ensureBoxReady();
    return box.watch();
  }

  Future<List<LoyaltyCard>> getAllLoyaltyCards() async {
    final box = await _ensureBoxReady();
    return box.values.toList();
  }

  Future<void> addLoyaltyCard(LoyaltyCard card) async {
    final box = await _ensureBoxReady();
    await box.add(card);
  }

  Future<void> removeLoyaltyCard(LoyaltyCard card) async {
    final box = await _ensureBoxReady();
    final target = box.values.firstWhere((c) => c.id == card.id);
    await target.delete();
  }

  Future<void> updateLoyaltyCard(
    LoyaltyCard original,
    LoyaltyCard updated,
  ) async {
    final box = await _ensureBoxReady();
    final index =
        box.values.toList().indexWhere((c) => c.id == original.id);
    if (index == -1) {
      throw Exception('Loyalty card not found for update');
    }
    await box.putAt(index, updated);
  }

  /// Counts one barcode display of the card with [id] (see
  /// [markLoyaltyUsed]) on the stored instance, so callers holding a detached
  /// copy (widget deep link) still update the box. Unknown ids are ignored.
  Future<void> recordUse(String id, {DateTime? now}) async {
    final box = await _ensureBoxReady();
    LoyaltyCard? stored;
    for (final c in box.values) {
      if (c.id == id) {
        stored = c;
        break;
      }
    }
    if (stored == null) return;
    markLoyaltyUsed(stored, now ?? DateTime.now());
    await stored.save();
  }

  /// [recordUse] for the barcode_shown call sites: never throws, never
  /// blocks the barcode from rendering.
  void recordUseInBackground(String id) {
    unawaited(recordUse(id).catchError((Object e, StackTrace st) {
      ErrorReporter.report(e, st, reason: 'LoyaltyCardService.recordUse');
    }));
  }

  Future<void> deleteAllData() async {
    final box = await _ensureBoxReady();
    await box.deleteAll(box.keys);
  }

  Future<Box<LoyaltyCard>> _ensureBoxReady() async {
    if (_box?.isOpen == true) {
      return _box!;
    }
    await init();
    if (_box == null) {
      throw StateError('Loyalty card box could not be opened');
    }
    return _box!;
  }

  Future<void> _openEncryptedBox() async {
    _box = await _opener.open<LoyaltyCard>(
      boxName: LOYALTY_CARD_BOX_NAME,
      keyName: LOYALTY_CARD_SECURE_STORAGE_KEY,
    );
  }
}
