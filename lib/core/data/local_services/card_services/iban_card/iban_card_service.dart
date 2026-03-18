import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:wallet_app/core/constants/keys.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';

class IbanCardService {
  IbanCardService._internal();
  static final IbanCardService _instance = IbanCardService._internal();
  factory IbanCardService() => _instance;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  Box<IbanCard>? _ibanCard;
  Future<void>? _openingFuture;

  Future<void> init() async {
    if (_ibanCard?.isOpen == true) return;

    if (_openingFuture != null) {
      await _openingFuture;
      return;
    }

    final completer = Completer<void>();
    _openingFuture = completer.future;

    try {
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(IbanCardAdapter());
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

  Future<void> deleteAllData() async {
    final box = await _ensureBoxReady();
    await box.deleteAll(box.keys);
  }

  Future<List<IbanCard>> getAllIbanCards() async {
    try {
      final box = await _ensureBoxReady();
      return box.values.toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addIbanCard(final IbanCard ibanCard) async {
    final box = await _ensureBoxReady();
    try {
      await box.add(ibanCard);
    } catch (e) {
      throw Exception('Failed to add IBAN card');
    }
  }

  Future<void> removeIbanCard(final IbanCard ibanCard) async {
    final box = await _ensureBoxReady();
    try {
      final ibanCardToRemove = box.values.firstWhere((element) {
        return element.id == ibanCard.id;
      });
      await ibanCardToRemove.delete();
    } catch (e) {
      throw Exception('IBAN card not found');
    }
  }

  // Yeni eklenen güncelleme metodu
  Future<void> updateIbanCard(
      IbanCard originalCard, IbanCard updatedCard) async {
    final box = await _ensureBoxReady();
    try {
      final index = box.values.toList().indexWhere((card) {
        return card.id == originalCard.id;
      });

      if (index != -1) {
        await box.putAt(index, updatedCard);
      } else {
        throw Exception('IBAN card not found for update');
      }
    } catch (e) {
      throw Exception('Failed to update IBAN card');
    }
  }

  Future<Box<IbanCard>> _ensureBoxReady() async {
    if (_ibanCard?.isOpen == true) {
      return _ibanCard!;
    }

    await init();
    if (_ibanCard == null) {
      throw StateError('IBAN card box could not be opened');
    }
    return _ibanCard!;
  }

  Future<void> _openEncryptedBox() async {
    List<int> encryptionKey;
    final boxExists = await Hive.boxExists(I_CARD_BOX_NAME);

    if (!boxExists) {
      final secureKey = Hive.generateSecureKey();
      encryptionKey = secureKey;
      await _secureStorage.write(
        key: I_CARD_SECURE_STORAGE_KEY,
        value: json.encode(secureKey),
      );
    } else {
      final storedKey =
          await _secureStorage.read(key: I_CARD_SECURE_STORAGE_KEY);
      if (storedKey == null) {
        throw Exception('Missing encryption key for IBAN card storage');
      }
      encryptionKey = (json.decode(storedKey) as List<dynamic>).cast<int>();
    }

    _ibanCard = await Hive.openBox(
      I_CARD_BOX_NAME,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  }
}
