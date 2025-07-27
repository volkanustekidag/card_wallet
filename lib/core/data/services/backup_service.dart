import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/models/credit_card_model/credit_card.dart';
import '../../domain/models/iban_card_model/iban_card.dart';
import '../../constants/keys.dart';

class BackupService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<Box<CreditCard>> _getCreditCardsBox() async {
    if (Hive.isBoxOpen(C_CARD_BOX_NAME)) {
      return Hive.box<CreditCard>(C_CARD_BOX_NAME);
    }

    try {
      final secureKey =
          await _secureStorage.read(key: C_CARD_SECURE_STORAGE_KEY);
      if (secureKey != null) {
        List<int> encryptionKey =
            (json.decode(secureKey) as List<dynamic>).cast<int>();
        return await Hive.openBox<CreditCard>(
          C_CARD_BOX_NAME,
          encryptionCipher: HiveAesCipher(encryptionKey),
        );
      }
    } catch (e) {
      print('Error opening credit cards box with encryption: $e');
    }
    return await Hive.openBox<CreditCard>(C_CARD_BOX_NAME);
  }

  Future<Box<IbanCard>> _getIbanCardsBox() async {
    if (Hive.isBoxOpen(I_CARD_BOX_NAME)) {
      return Hive.box<IbanCard>(I_CARD_BOX_NAME);
    }

    try {
      final secureKey =
          await _secureStorage.read(key: I_CARD_SECURE_STORAGE_KEY);
      if (secureKey != null) {
        List<int> encryptionKey =
            (json.decode(secureKey) as List<dynamic>).cast<int>();
        return await Hive.openBox<IbanCard>(
          I_CARD_BOX_NAME,
          encryptionCipher: HiveAesCipher(encryptionKey),
        );
      }
    } catch (e) {
      print('Error opening iban cards box with encryption: $e');
    }
    return await Hive.openBox<IbanCard>(I_CARD_BOX_NAME);
  }

  Future<Map<String, dynamic>> exportAllData() async {
    final creditCardsBox = await _getCreditCardsBox();
    final ibanCardsBox = await _getIbanCardsBox();

    print('Credit cards count: ${creditCardsBox.length}');
    print('IBAN cards count: ${ibanCardsBox.length}');

    Map<String, dynamic> backup = {
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'creditCards': [],
        'ibanCards': [],
        'verification': null,
      }
    };

    for (var i = 0; i < creditCardsBox.length; i++) {
      final card = creditCardsBox.getAt(i);
      if (card != null) {
        backup['data']['creditCards'].add({
          'id': card.id,
          'bankName': card.bankName,
          'creditCardNumber': card.creditCardNumber,
          'cardHolder': card.cardHolder,
          'expirationDate': card.expirationDate,
          'cvc2': card.cvc2,
          'cardColorId': card.cardColorId,
        });
      }
    }

    for (var i = 0; i < ibanCardsBox.length; i++) {
      final card = ibanCardsBox.getAt(i);
      if (card != null) {
        backup['data']['ibanCards'].add({
          'id': card.id,
          'bankName': card.bankName,
          'cardHolder': card.cardHolder,
          'iban': card.iban,
          'swiftCode': card.swiftCode,
        });
      }
    }

    return backup;
  }

  Future<String> createBackupFile() async {
    try {
      await _requestStoragePermission();

      final backupData = await exportAllData();
      final jsonString = JsonEncoder.withIndent('  ').convert(backupData);

      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        if (directory != null) {
          directory = Directory('${directory.path}/Download');
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Dosya dizini bulunamadı');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'card_wallet_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(jsonString);
      return file.path;
    } catch (e) {
      throw Exception('Yedekleme oluşturulurken hata: $e');
    }
  }

  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
    }
  }

  Future<void> restoreFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        await restoreFromFileContent(file);
      }
    } catch (e) {
      throw Exception('Geri yükleme sırasında hata: $e');
    }
  }

  Future<void> restoreFromFileContent(File file) async {
    try {
      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      if (!backupData.containsKey('version') ||
          !backupData.containsKey('data')) {
        throw Exception('Geçersiz yedekleme dosyası formatı');
      }

      await clearAllData();

      final data = backupData['data'] as Map<String, dynamic>;

      await _restoreCreditCards(data['creditCards']);
      await _restoreIbanCards(data['ibanCards']);
    } catch (e) {
      throw Exception('Geri yükleme sırasında hata: $e');
    }
  }

  Future<void> _restoreCreditCards(List<dynamic>? creditCardsData) async {
    if (creditCardsData == null) return;

    final box = await _getCreditCardsBox();

    for (var cardData in creditCardsData) {
      final card = CreditCard(
        id: cardData['id'],
        bankName: cardData['bankName'],
        creditCardNumber: cardData['creditCardNumber'],
        cardHolder: cardData['cardHolder'],
        expirationDate: cardData['expirationDate'],
        cvc2: cardData['cvc2'],
        cardColorId: cardData['cardColorId'],
      );
      await box.add(card);
    }
  }

  Future<void> _restoreIbanCards(List<dynamic>? ibanCardsData) async {
    if (ibanCardsData == null) return;

    final box = await _getIbanCardsBox();

    for (var cardData in ibanCardsData) {
      final card = IbanCard(
        id: cardData['id'],
        bankName: cardData['bankName'],
        cardHolder: cardData['cardHolder'],
        iban: cardData['iban'],
        swiftCode: cardData['swiftCode'],
      );
      await box.add(card);
    }
  }

  Future<void> clearAllData() async {
    final creditCardsBox = await _getCreditCardsBox();
    final ibanCardsBox = await _getIbanCardsBox();

    await creditCardsBox.clear();
    await ibanCardsBox.clear();
  }
}
