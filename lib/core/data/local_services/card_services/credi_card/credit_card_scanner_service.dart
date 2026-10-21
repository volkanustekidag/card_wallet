import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/services/camera_permission_service.dart';
import 'package:wallet_app/core/services/app_lock_service.dart';
import 'package:wallet_app/core/utils/scan_photo_cleanup.dart';
import 'package:wallet_app/core/utils/card_number_layout.dart';
import 'package:wallet_app/core/utils/validators.dart';

class CreditCardScannerService {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();

  // Kredi kartı tarama
  Future<Map<String, String>?> scanCreditCard() async {
    XFile? photo;
    try {
      if (!await CameraPermissionService.ensureGranted()) {
        return null;
      }

      // Kameradan fotoğraf çek
      photo = await AppLockService.guard(() => _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
        preferredCameraDevice: CameraDevice.rear,
      ));

      if (photo == null) return null;

      // OCR ile metni oku
      final inputImage = InputImage.fromFilePath(photo.path);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      // Kredi kartı bilgilerini parse et
      return _parseCreditCardInfo(recognizedText.text);
    } catch (e) {
      Get.context?.showErrorSnackBar('failedToScanCreditCard'.tr());
      return null;
    } finally {
      await deleteScanPhoto(photo, fromCamera: true);
    }
  }

  // Galeriden fotoğraf seç
  Future<Map<String, String>?> scanFromGallery() async {
    XFile? photo;
    try {
      photo = await AppLockService.guard(() => _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      ));

      if (photo == null) return null;

      final inputImage = InputImage.fromFilePath(photo.path);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      return _parseCreditCardInfo(recognizedText.text);
    } catch (e) {
      return null;
    } finally {
      await deleteScanPhoto(photo, fromCamera: false);
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
    final cardNumber = extractCardNumber(text);
    if (cardNumber != null) {
      cardInfo['cardNumber'] = CardNumberLayout.format(cardNumber);
    }

    for (String line in lines) {
      final cleanLine = line.trim().toUpperCase();

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

  /// Finds a 13-19 digit card number (Amex 15, Diners 14, Visa 19…) in OCR
  /// text. Groups may be separated by spaces or dashes; only candidates that
  /// pass the Luhn check are accepted, which filters out phone numbers and
  /// account numbers printed on the card.
  @visibleForTesting
  static String? extractCardNumber(String text) {
    final run = RegExp(r'\d+(?:[ \-]\d+)*');
    for (final line in text.split('\n')) {
      for (final match in run.allMatches(line)) {
        final groups = match.group(0)!.split(RegExp(r'[ \-]'));
        // Try every run of consecutive groups and keep the longest valid
        // one, so "4111 1111 1111 1111 12/30" or a 19-digit number isn't
        // cut short by a prefix that happens to pass Luhn.
        String? best;
        for (var i = 0; i < groups.length; i++) {
          var digits = '';
          for (var j = i; j < groups.length; j++) {
            digits += groups[j];
            if (digits.length > CardNumberLayout.maxDigits) break;
            if (digits.length >= CardNumberLayout.minDigits &&
                CardValidators.isValidLuhn(digits) &&
                (best == null || digits.length > best.length)) {
              best = digits;
            }
          }
        }
        if (best != null) return best;
      }
    }
    return null;
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
