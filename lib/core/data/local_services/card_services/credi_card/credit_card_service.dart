import 'dart:async';

import 'package:hive/hive.dart';
import 'package:wallet_app/core/constants/keys.dart';
import 'package:wallet_app/core/data/storage/encrypted_box_opener.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/services/card_reminder_service.dart';

class CreditCardService {
  CreditCardService._internal();
  static final CreditCardService _instance = CreditCardService._internal();
  factory CreditCardService() => _instance;

  final EncryptedBoxOpener _opener = EncryptedBoxOpener();
  Box<CreditCard>? _creditCards;
  Future<void>? _openingFuture;

  Future<void> init() async {
    if (_creditCards?.isOpen == true) return;

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
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(CreditCardAdapter());
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

  /// Stream of every add / put / delete that lands in the credit-card box.
  /// Consumers (e.g. HomeController) listen so they can refresh derived
  /// state without polling.
  Future<Stream<BoxEvent>> watch() async {
    final box = await _ensureBoxReady();
    return box.watch();
  }

  Future<void> deleteAllData() async {
    final box = await _ensureBoxReady();
    await box.deleteAll(box.keys);
  }

  Future<List<CreditCard>> getAllCreditCards() async {
    final box = await _ensureBoxReady();
    return box.values.toList();
  }

  Future<void> removeToCreditCard(final CreditCard creditCard) async {
    final box = await _ensureBoxReady();
    final creditCardToRemove =
        box.values.firstWhere((element) => element == creditCard);

    await creditCardToRemove.delete();
    await CardReminderService().cancelForCard(creditCard);
  }

  Future<void> addToCreditCard(final CreditCard creditCard) async {
    final box = await _ensureBoxReady();
    await box.add(creditCard);
    await CardReminderService().scheduleForCard(creditCard);
  }

  // Yeni eklenen güncelleme metodu
  Future<void> updateCreditCard(
      CreditCard originalCard, CreditCard updatedCard) async {
    final box = await _ensureBoxReady();
    final index = box.values.toList().indexWhere((card) =>
        card.id == originalCard.id &&
        card.creditCardNumber == originalCard.creditCardNumber);

    if (index != -1) {
      await CardReminderService().cancelForCard(originalCard);
      await box.putAt(index, updatedCard);
      await CardReminderService().scheduleForCard(updatedCard);
    } else {
      throw Exception('Credit card not found for update');
    }
  }

  Future<Box<CreditCard>> _ensureBoxReady() async {
    if (_creditCards?.isOpen == true) {
      return _creditCards!;
    }

    await init();

    if (_creditCards == null) {
      throw StateError('Credit card box could not be opened');
    }

    return _creditCards!;
  }

  Future<void> _openEncryptedBox() async {
    _creditCards = await _opener.open<CreditCard>(
      boxName: C_CARD_BOX_NAME,
      keyName: C_CARD_SECURE_STORAGE_KEY,
    );
  }
}
