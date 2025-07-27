import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:wallet_app/core/constants/keys.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';

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
    } else {
      await openBox();
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
    await _ibanCard.deleteAll(_ibanCard.keys);
  }

  Future<List<IbanCard>> getAllIbanCards() async {
    try {
      // Model artık hem int hem string ID'leri handle ediyor
      return _ibanCard.values.toList();
    } catch (e) {
      print('Error getting all IBAN cards: $e');
      return [];
    }
  }

  Future<void> addIbanCard(final IbanCard ibanCard) async {
    try {
      await _ibanCard.add(ibanCard);
    } catch (e) {
      print('Error adding IBAN card: $e');
      throw Exception('Failed to add IBAN card');
    }
  }

  Future<void> removeIbanCard(final IbanCard ibanCard) async {
    try {
      final ibanCardToRemove = _ibanCard.values.firstWhere((element) {
        // ID'leri string olarak karşılaştır
        return element.id == ibanCard.id;
      });
      await ibanCardToRemove.delete();
    } catch (e) {
      print('Error removing IBAN card: $e');
      throw Exception('IBAN card not found');
    }
  }

  // Yeni eklenen güncelleme metodu
  Future<void> updateIbanCard(
      IbanCard originalCard, IbanCard updatedCard) async {
    try {
      final index = _ibanCard.values.toList().indexWhere((card) {
        // ID'leri string olarak karşılaştır
        return card.id == originalCard.id;
      });

      if (index != -1) {
        await _ibanCard.putAt(index, updatedCard);
      } else {
        throw Exception('IBAN card not found for update');
      }
    } catch (e) {
      print('Error updating IBAN card: $e');
      throw Exception('Failed to update IBAN card');
    }
  }
}
