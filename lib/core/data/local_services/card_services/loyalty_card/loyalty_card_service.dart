import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:wallet_app/core/constants/keys.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';

class LoyaltyCardService {
  LoyaltyCardService._internal();
  static final LoyaltyCardService _instance = LoyaltyCardService._internal();
  factory LoyaltyCardService() => _instance;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
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
    List<int> encryptionKey;
    final boxExists = await Hive.boxExists(LOYALTY_CARD_BOX_NAME);

    if (!boxExists) {
      final secureKey = Hive.generateSecureKey();
      encryptionKey = secureKey;
      await _secureStorage.write(
        key: LOYALTY_CARD_SECURE_STORAGE_KEY,
        value: json.encode(secureKey),
      );
    } else {
      final storedKey =
          await _secureStorage.read(key: LOYALTY_CARD_SECURE_STORAGE_KEY);
      if (storedKey == null) {
        throw Exception('Missing encryption key for loyalty card storage');
      }
      encryptionKey = (json.decode(storedKey) as List<dynamic>).cast<int>();
    }

    _box = await Hive.openBox<LoyaltyCard>(
      LOYALTY_CARD_BOX_NAME,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  }
}
