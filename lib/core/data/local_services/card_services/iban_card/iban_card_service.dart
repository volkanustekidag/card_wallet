import 'dart:async';

import 'package:hive/hive.dart';
import 'package:wallet_app/core/constants/keys.dart';
import 'package:wallet_app/core/data/storage/encrypted_box_opener.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/services/error_reporter.dart';

class IbanCardService {
  IbanCardService._internal();
  static final IbanCardService _instance = IbanCardService._internal();
  factory IbanCardService() => _instance;

  final EncryptedBoxOpener _opener = EncryptedBoxOpener();
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
    // The first caller gets the error via rethrow; without a listener the
    // completer's copy would also surface as an unhandled zone error.
    completer.future.ignore();

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

  Future<Stream<BoxEvent>> watch() async {
    final box = await _ensureBoxReady();
    return box.watch();
  }

  Future<void> deleteAllData() async {
    final box = await _ensureBoxReady();
    await box.deleteAll(box.keys);
  }

  Future<List<IbanCard>> getAllIbanCards() async {
    try {
      final box = await _ensureBoxReady();
      return box.values.toList();
    } catch (e, st) {
      // Callers render an empty list; make the failure visible.
      ErrorReporter.report(e, st, reason: 'getAllIbanCards');
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
    _ibanCard = await _opener.open<IbanCard>(
      boxName: I_CARD_BOX_NAME,
      keyName: I_CARD_SECURE_STORAGE_KEY,
    );
  }
}
