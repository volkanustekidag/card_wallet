import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:wallet_app/core/constants/keys.dart';
import 'package:wallet_app/domain/models/credit_card_model/credit_card.dart';

class CreditCardService {
  late Box<CreditCard> _creditCards;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(CreditCardAdapter());
    }

    bool boxExists = await Hive.boxExists(C_CARD_BOX_NAME);

    if (boxExists == false) {
      final secureKey = Hive.generateSecureKey();
      const secureStorage = FlutterSecureStorage();

      _creditCards = await Hive.openBox(
        C_CARD_BOX_NAME,
        encryptionCipher: HiveAesCipher(secureKey),
      );

      await secureStorage.write(
        key: C_CARD_SECURE_STORAGE_KEY,
        value: json.encode(secureKey),
      );
    }
  }

  Future<void> openBox() async {
    final secureKey =
        await const FlutterSecureStorage().read(key: C_CARD_SECURE_STORAGE_KEY);
    List<int> encryptionKey =
        (json.decode(secureKey!) as List<dynamic>).cast<int>();
    _creditCards = await Hive.openBox(
      C_CARD_BOX_NAME,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  }

  Future<void> deleteAllData() async {
    await openBox();
    await _creditCards.deleteAll(_creditCards.keys);
  }

  Future<List<CreditCard>> getAllCreditCards() async {
    return _creditCards.values.toList();
  }

  Future<void> removeToCreditCard(final CreditCard creditCard) async {
    final creditCardToRemove =
        _creditCards.values.firstWhere((element) => element == creditCard);

    creditCardToRemove.delete();
  }

  Future<void> addToCreditCard(final CreditCard creditCard) async {
    _creditCards.add(creditCard);
  }
}
