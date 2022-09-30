import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:wallet_app/core/constants/keys.dart';
import 'package:wallet_app/domain/models/iban_card_model/iban_card.dart';

class IbanCardService {
  late Box<IbanCard> _ibanCard;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(IbanCardAdapter());
    }

    bool boxExists = await Hive.boxExists(I_CARD_BOX_NAME);

    if (boxExists == false) {
      final secureKey = Hive.generateSecureKey();
      const secureStorage = FlutterSecureStorage();

      _ibanCard = await Hive.openBox(
        I_CARD_BOX_NAME,
        encryptionCipher: HiveAesCipher(secureKey),
      );

      await secureStorage.write(
        key: I_CARD_SECURE_STORAGE_KEY,
        value: json.encode(secureKey),
      );
    }
  }

  Future<void> openBox() async {
    final secureKey =
        await const FlutterSecureStorage().read(key: I_CARD_SECURE_STORAGE_KEY);
    List<int> encryptionKey =
        (json.decode(secureKey!) as List<dynamic>).cast<int>();
    _ibanCard = await Hive.openBox(
      I_CARD_BOX_NAME,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  }

  Future<void> deleteAllData() async {
    await openBox();
    _ibanCard.deleteAll(_ibanCard.keys);
  }

  Future<List<IbanCard>> getAllIbanCards() async {
    return _ibanCard.values.toList();
  }

  Future<void> addIbanCard(final IbanCard ibanCard) async {
    _ibanCard.add(ibanCard);
  }

  Future<void> removeIbanCard(final IbanCard ibanCard) async {
    final ibanCardToRemove =
        _ibanCard.values.firstWhere((element) => element == ibanCard);
    await ibanCardToRemove.delete();
  }
}
