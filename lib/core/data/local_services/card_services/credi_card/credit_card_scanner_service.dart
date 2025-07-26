import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CreditCardScannerService {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();

  // Kredi kartı tarama
  Future<Map<String, String>?> scanCreditCard() async {
    try {
      // Kameradan fotoğraf çek
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo == null) return null;

      // OCR ile metni oku
      final inputImage = InputImage.fromFilePath(photo.path);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      // Kredi kartı bilgilerini parse et
      return _parseCreditCardInfo(recognizedText.text);
    } catch (e) {
      print('Credit card scan error: $e');
      Get.snackbar('Error', 'Failed to scan credit card: ${e.toString()}');
      return null;
    }
  }

  // Galeriden fotoğraf seç
  Future<Map<String, String>?> scanFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (photo == null) return null;

      final inputImage = InputImage.fromFilePath(photo.path);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      return _parseCreditCardInfo(recognizedText.text);
    } catch (e) {
      print('Gallery scan error: $e');
      Get.snackbar('Error', 'Failed to scan from gallery: ${e.toString()}');
      return null;
    }
  }

  // Kredi kartı bilgilerini parse et
  Map<String, String> _parseCreditCardInfo(String text) {
    Map<String, String> cardInfo = {
      'cardNumber': '',
      'expiryDate': '',
      'cardHolder': '',
    };

    final lines = text.split('\n');

    for (String line in lines) {
      final cleanLine = line.trim().toUpperCase();

      // Kart numarası (16 haneli)
      final cardNumberMatch =
          RegExp(r'\b(\d{4}[\s\-]?\d{4}[\s\-]?\d{4}[\s\-]?\d{4})\b')
              .firstMatch(cleanLine);
      if (cardNumberMatch != null && cardInfo['cardNumber']!.isEmpty) {
        cardInfo['cardNumber'] =
            cardNumberMatch.group(1)!.replaceAll(RegExp(r'[\s\-]'), ' ');
        // 4'lü gruplara böl
        final digits = cardInfo['cardNumber']!.replaceAll(' ', '');
        if (digits.length == 16) {
          cardInfo['cardNumber'] =
              '${digits.substring(0, 4)} ${digits.substring(4, 8)} ${digits.substring(8, 12)} ${digits.substring(12, 16)}';
        }
      }

      // Son kullanma tarihi (MM/YY veya MM/YYYY formatında)
      final expiryMatch = RegExp(r'\b(0[1-9]|1[0-2])[\s\/\-]?(\d{2}|\d{4})\b')
          .firstMatch(cleanLine);
      if (expiryMatch != null && cardInfo['expiryDate']!.isEmpty) {
        String month = expiryMatch.group(1)!;
        String year = expiryMatch.group(2)!;

        // Yılı 2 haneli yap
        if (year.length == 4) {
          year = year.substring(2);
        }

        cardInfo['expiryDate'] = '$month/$year';
      }

      // Kart sahibi ismi (büyük harflerle yazılmış uzun kelimeler)
      if (cleanLine.length > 10 &&
          !cleanLine.contains(RegExp(r'\d')) &&
          cleanLine.split(' ').length >= 2 &&
          cardInfo['cardHolder']!.isEmpty &&
          !_isCommonBankName(cleanLine)) {
        cardInfo['cardHolder'] = _formatCardHolderName(cleanLine);
      }
    }

    return cardInfo;
  }

  // Kart sahibi ismini formatla
  String _formatCardHolderName(String name) {
    return name
        .split(' ')
        .where((word) => word.length > 1)
        .map((word) => word[0] + word.substring(1).toLowerCase())
        .join(' ');
  }

  // Yaygın banka isimlerini filtrele
  bool _isCommonBankName(String text) {
    final commonBankNames = [
      'VISA',
      'MASTERCARD',
      'AMERICAN EXPRESS',
      'DISCOVER',
      'GARANTI',
      'AKBANK',
      'ISBANKASI',
      'HALKBANK',
      'ZIRAAT',
      'YAPI KREDI',
      'TEB',
      'ING',
      'QNB',
      'DENIZBANK'
    ];

    return commonBankNames.any((bank) => text.contains(bank));
  }

  // Servisi temizle
  void dispose() {
    _textRecognizer.close();
  }
}
