import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:permission_handler/permission_handler.dart';

class QRIbanScannerService {
  final ImagePicker _picker = ImagePicker();
  final BarcodeScanner _barcodeScanner = BarcodeScanner();

  // QR kod ile IBAN tarama
  Future<Map<String, String>?> scanQRForIban() async {
    try {
      // Kamera izni kontrol et
      final cameraPermission = await Permission.camera.request();
      if (!cameraPermission.isGranted) {
        Get.snackbar('Error', 'Camera permission is required');
        return null;
      }

      // Kameradan QR kod tara
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo == null) return null;

      // QR kodu decode et
      final inputImage = InputImage.fromFilePath(photo.path);
      final List<Barcode> barcodes =
          await _barcodeScanner.processImage(inputImage);

      if (barcodes.isEmpty) {
        Get.snackbar('Info', 'No QR code found in the image');
        return null;
      }

      // İlk QR kodu parse et
      return _parseQRContent(barcodes.first.rawValue ?? '');
    } catch (e) {
      print('QR scan error: $e');
      Get.snackbar('Error', 'Failed to scan QR code: ${e.toString()}');
      return null;
    }
  }

  // Galeriden QR kod seç
  Future<Map<String, String>?> scanQRFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (photo == null) return null;

      final inputImage = InputImage.fromFilePath(photo.path);
      final List<Barcode> barcodes =
          await _barcodeScanner.processImage(inputImage);

      if (barcodes.isEmpty) {
        Get.snackbar('Info', 'No QR code found in the image');
        return null;
      }

      return _parseQRContent(barcodes.first.rawValue ?? '');
    } catch (e) {
      print('Gallery QR scan error: $e');
      Get.snackbar('Error', 'Failed to scan QR from gallery: ${e.toString()}');
      return null;
    }
  }

  // QR kod içeriğini parse et - Geliştirilmiş versiyon
  Map<String, String> _parseQRContent(String qrContent) {
    Map<String, String> ibanInfo = {
      'iban': '',
      'cardHolder': '',
      'bankName': '',
      'swiftCode': '',
    };

    print('QR Content: $qrContent');

    // HTML entity decode işlemi
    String cleanContent = _decodeHtmlEntities(qrContent);
    print('Decoded QR Content: $cleanContent');

    try {
      // Format 1: IBAN direkt QR kod olarak
      if (_isValidIban(cleanContent.trim())) {
        ibanInfo['iban'] = _formatIban(cleanContent.trim());
        return ibanInfo;
      }

      // Format 2: JSON formatında
      if (cleanContent.startsWith('{') && cleanContent.endsWith('}')) {
        return _parseJsonQR(cleanContent, ibanInfo);
      }

      // Format 3: Key-value pairs (örn: IBAN=TR330006100519786457841526;NAME=JOHN DOE;BANK=GARANTI)
      if (cleanContent.contains('=')) {
        return _parseKeyValueQR(cleanContent, ibanInfo);
      }

      // Format 4: Çok satırlı format
      if (cleanContent.contains('\n')) {
        return _parseMultiLineQR(cleanContent, ibanInfo);
      }

      // Format 5: URL formatında (bazı bankalar)
      if (cleanContent.startsWith('http')) {
        return _parseUrlQR(cleanContent, ibanInfo);
      }

      // Format 6: Gömülü IBAN arama - GELİŞTİRİLMİŞ
      final extractedData = _extractIbanAndName(cleanContent);
      if (extractedData['iban'] != null && extractedData['iban']!.isNotEmpty) {
        ibanInfo['iban'] = extractedData['iban']!;
      }
      if (extractedData['name'] != null && extractedData['name']!.isNotEmpty) {
        ibanInfo['cardHolder'] = extractedData['name']!;
      }

      // Banka adı çıkarma
      final bankName = _extractBankName(cleanContent);
      if (bankName.isNotEmpty) {
        ibanInfo['bankName'] = bankName;
      }
    } catch (e) {
      print('QR parse error: $e');
    }

    return ibanInfo;
  }

  // JSON formatındaki QR'ı parse et
  Map<String, String> _parseJsonQR(
      String qrContent, Map<String, String> ibanInfo) {
    try {
      // Basit JSON parsing (dart:convert kullanmadan)
      final content =
          qrContent.replaceAll('{', '').replaceAll('}', '').replaceAll('"', '');
      final pairs = content.split(',');

      for (String pair in pairs) {
        final keyValue = pair.split(':');
        if (keyValue.length == 2) {
          final key = keyValue[0].trim().toLowerCase();
          final value = keyValue[1].trim();

          if (key.contains('iban') || key.contains('account')) {
            if (_isValidIban(value)) {
              ibanInfo['iban'] = _formatIban(value);
            }
          } else if (key.contains('name') ||
              key.contains('holder') ||
              key.contains('owner')) {
            ibanInfo['cardHolder'] = _formatName(value);
          } else if (key.contains('bank')) {
            ibanInfo['bankName'] = value.toUpperCase();
          } else if (key.contains('swift') || key.contains('bic')) {
            ibanInfo['swiftCode'] = value.toUpperCase();
          }
        }
      }
    } catch (e) {
      print('JSON QR parse error: $e');
    }
    return ibanInfo;
  }

  // Key-value formatındaki QR'ı parse et
  Map<String, String> _parseKeyValueQR(
      String qrContent, Map<String, String> ibanInfo) {
    final pairs = qrContent.split(RegExp(r'[;&|\n]'));

    for (String pair in pairs) {
      final keyValue = pair.split('=');
      if (keyValue.length == 2) {
        final key = keyValue[0].trim().toUpperCase();
        final value = keyValue[1].trim();

        switch (key) {
          case 'IBAN':
          case 'ACCOUNT':
          case 'ACCOUNTNUMBER':
          case 'HESAPNO':
            if (_isValidIban(value)) {
              ibanInfo['iban'] = _formatIban(value);
            }
            break;
          case 'NAME':
          case 'HOLDER':
          case 'ACCOUNTHOLDER':
          case 'OWNER':
          case 'SAHIP':
          case 'HESAPSAHIBI':
            ibanInfo['cardHolder'] = _formatName(value);
            break;
          case 'BANK':
          case 'BANKNAME':
          case 'BANKA':
            ibanInfo['bankName'] = value.toUpperCase();
            break;
          case 'SWIFT':
          case 'BIC':
          case 'SWIFTCODE':
            ibanInfo['swiftCode'] = value.toUpperCase();
            break;
        }
      }
    }
    return ibanInfo;
  }

  // Çok satırlı formatı parse et
  Map<String, String> _parseMultiLineQR(
      String qrContent, Map<String, String> ibanInfo) {
    final lines = qrContent.split('\n');

    for (String line in lines) {
      final trimmedLine = line.trim();

      if (trimmedLine.isEmpty) continue;

      // IBAN arama - hem direkt hem de TR ile başlayan pattern
      if (_isValidIban(trimmedLine)) {
        ibanInfo['iban'] = _formatIban(trimmedLine);
      } else {
        // Satır içinde IBAN arama
        final ibanMatch =
            RegExp(r'TR\d{24}').firstMatch(trimmedLine.toUpperCase());
        if (ibanMatch != null) {
          ibanInfo['iban'] = _formatIban(ibanMatch.group(0)!);
        }
      }

      // İsim arama - büyük harflerle yazılmış uzun kelimeler ve Türkçe isimler
      if (_isLikelyPersonName(trimmedLine)) {
        ibanInfo['cardHolder'] = _formatName(trimmedLine);
      }

      // Banka adı arama
      if (_isLikelyBankName(trimmedLine)) {
        ibanInfo['bankName'] = trimmedLine.toUpperCase();
      }

      // Key-value formatı kontrol et
      if (trimmedLine.contains('=')) {
        final keyValue = trimmedLine.split('=');
        if (keyValue.length == 2) {
          final key = keyValue[0].trim().toUpperCase();
          final value = keyValue[1].trim();

          if ((key.contains('IBAN') || key.contains('ACCOUNT')) &&
              _isValidIban(value)) {
            ibanInfo['iban'] = _formatIban(value);
          } else if (key.contains('NAME') || key.contains('HOLDER')) {
            ibanInfo['cardHolder'] = _formatName(value);
          }
        }
      }
    }
    return ibanInfo;
  }

  // URL formatını parse et
  Map<String, String> _parseUrlQR(
      String qrContent, Map<String, String> ibanInfo) {
    try {
      final uri = Uri.parse(qrContent);
      final params = uri.queryParameters;

      // Query parameters kontrol et
      params.forEach((key, value) {
        final lowerKey = key.toLowerCase();

        if (lowerKey.contains('iban') || lowerKey.contains('account')) {
          if (_isValidIban(value)) {
            ibanInfo['iban'] = _formatIban(value);
          }
        } else if (lowerKey.contains('name') || lowerKey.contains('holder')) {
          ibanInfo['cardHolder'] = _formatName(value);
        } else if (lowerKey.contains('bank')) {
          ibanInfo['bankName'] = value.toUpperCase();
        } else if (lowerKey.contains('swift') || lowerKey.contains('bic')) {
          ibanInfo['swiftCode'] = value.toUpperCase();
        }
      });

      // URL path'inde de IBAN arama
      final pathIban = RegExp(r'TR\d{24}').firstMatch(uri.path.toUpperCase());
      if (pathIban != null && ibanInfo['iban']!.isEmpty) {
        ibanInfo['iban'] = _formatIban(pathIban.group(0)!);
      }
    } catch (e) {
      print('URL QR parse error: $e');

      // URL parse edilemezse manuel olarak parameter arama
      if (qrContent.contains('?')) {
        final parts = qrContent.split('?');
        if (parts.length > 1) {
          final queryString = parts[1];
          final params = queryString.split('&');

          for (String param in params) {
            final keyValue = param.split('=');
            if (keyValue.length == 2) {
              final key = Uri.decodeComponent(keyValue[0]).toLowerCase();
              final value = Uri.decodeComponent(keyValue[1]);

              if (key.contains('iban') && _isValidIban(value)) {
                ibanInfo['iban'] = _formatIban(value);
              } else if (key.contains('name')) {
                ibanInfo['cardHolder'] = _formatName(value);
              }
            }
          }
        }
      }
    }
    return ibanInfo;
  }

  // Gömülü IBAN ve isim çıkarma metodu
  Map<String, String> _extractIbanAndName(String content) {
    Map<String, String> result = {
      'iban': '',
      'name': '',
    };

    // IBAN pattern - TR ile başlayıp 26 karakter uzunluğunda
    final ibanRegex = RegExp(r'TR\d{24}');
    final ibanMatch = ibanRegex.firstMatch(content.toUpperCase());

    if (ibanMatch != null) {
      result['iban'] = _formatIban(ibanMatch.group(0)!);

      // IBAN'dan sonraki kısmı analiz et
      final afterIban = content.substring(ibanMatch.end);

      // İsim çıkarma - IBAN'dan sonra gelen büyük harfli kelimeler
      final nameMatch = _extractNameAfterIban(afterIban);
      if (nameMatch.isNotEmpty) {
        result['name'] = nameMatch;
      }
    }

    return result;
  }

  // IBAN'dan sonra isim çıkarma
  String _extractNameAfterIban(String afterIban) {
    // Sayısal karakterleri temizle ve sadece harfleri al
    String cleanText = '';
    bool foundLetter = false;

    for (int i = 0; i < afterIban.length; i++) {
      String char = afterIban[i];

      if (RegExp(r'[A-Za-zÇĞIİÖŞÜçğıiöşü\s]').hasMatch(char)) {
        foundLetter = true;
        cleanText += char;
      } else if (foundLetter && RegExp(r'\d').hasMatch(char)) {
        // İsimden sonra sayı gelince dur
        break;
      }
    }

    // Temizlenmiş metni formatla
    cleanText = cleanText.trim();
    if (cleanText.length > 2) {
      return _formatName(cleanText);
    }

    return '';
  }

  // Geliştirilmiş banka adı çıkarma
  String _extractBankName(String content) {
    final bankPatterns = {
      'GARANTİ': ['GARANTI', 'GARANTIBBVA', 'BBVA'],
      'AKBANK': ['AKBANK', 'AK BANK'],
      'HALKBANK': ['HALKBANK', 'HALK BANK', 'HALK'],
      'ZİRAAT BANKASI': ['ZIRAAT', 'ZIRAT', 'TC ZIRAAT'],
      'VAKIFBANK': ['VAKIF', 'VAKIFBANK', 'VAKIF BANK'],
      'TEB': ['TEB', 'TURK EKONOMI'],
      'ING BANK': ['ING', 'ING BANK'],
      'QNB FİNANSBANK': ['QNB', 'FINANSBANK', 'QNB FINANSBANK'],
      'DENİZBANK': ['DENIZBANK', 'DENIZ BANK'],
      'HSBC': ['HSBC'],
      'YAPIKRED': ['YAPIKRED', 'YAPI KREDI'],
      'İŞ BANKASI': ['ISBANK', 'IS BANK', 'TURKIYE IS BANKASI'],
    };

    final upperContent = content.toUpperCase();

    for (String bankName in bankPatterns.keys) {
      for (String pattern in bankPatterns[bankName]!) {
        if (upperContent.contains(pattern)) {
          return bankName;
        }
      }
    }

    return '';
  }

  // Kişi ismi olma ihtimali kontrol et
  bool _isLikelyPersonName(String text) {
    final trimmed = text.trim();

    // Çok kısa veya çok uzun değil
    if (trimmed.length < 3 || trimmed.length > 50) return false;

    // Sadece harf, boşluk ve Türkçe karakterler içeriyor
    if (!RegExp(r'^[A-Za-zÇĞIİÖŞÜçğıiöşü\s]+$').hasMatch(trimmed)) return false;

    // En az 2 kelime var (ad soyad)
    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length < 2) return false;

    // Her kelime en az 2 karakter
    if (words.any((word) => word.length < 2)) return false;

    // IBAN içermiyor
    if (RegExp(r'TR\d{24}').hasMatch(trimmed.toUpperCase())) return false;

    // Sayı içermiyor
    if (RegExp(r'\d').hasMatch(trimmed)) return false;

    return true;
  }

  // Banka adı olma ihtimali - geliştirilmiş
  bool _isLikelyBankName(String text) {
    final bankKeywords = [
      'BANK',
      'BANKA',
      'GARANTİ',
      'GARANTI',
      'AKBANK',
      'HALKBANK',
      'HALK',
      'ZİRAAT',
      'ZIRAAT',
      'VAKIF',
      'VAKIFBANK',
      'TEB',
      'ING',
      'QNB',
      'DENİZBANK',
      'DENIZBANK',
      'FİNANSBANK',
      'FINANSBANK',
      'HSBC',
      'YAPIKREDI',
      'YAPI KREDİ',
      'İŞBANK',
      'ISBANK',
      'İŞ BANKASI',
      'KUVEYT TÜRK',
      'KUVEYT',
      'ALBARAKA',
      'ODEABANK',
      'ODEA'
    ];

    final upperText = text.toUpperCase().trim();

    // Çok kısa ise değil
    if (upperText.length < 3) return false;

    // Banka anahtar kelimesi içeriyor mu
    return bankKeywords.any((keyword) => upperText.contains(keyword));
  }

  // IBAN geçerliliği kontrol et - daha esnek
  bool _isValidIban(String iban) {
    final cleanIban =
        iban.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
    // Türk IBAN formatı: TR + 2 check digit + 5 banka kodu + 1 reserved + 16 hesap numarası = 26 karakter
    return RegExp(r'^TR\d{24}$').hasMatch(cleanIban) && cleanIban.length == 26;
  }

  // IBAN formatla - daha güvenli
  String _formatIban(String iban) {
    final cleanIban = iban.replaceAll(RegExp(r'[\s\-]'), '').toUpperCase();

    if (cleanIban.length == 26 && cleanIban.startsWith('TR')) {
      // TR00 0000 0000 0000 0000 0000 00 formatında döndür
      try {
        return '${cleanIban.substring(0, 4)} ${cleanIban.substring(4, 8)} ${cleanIban.substring(8, 12)} ${cleanIban.substring(12, 16)} ${cleanIban.substring(16, 20)} ${cleanIban.substring(20, 24)} ${cleanIban.substring(24, 26)}';
      } catch (e) {
        return cleanIban;
      }
    }
    return cleanIban;
  }

  // İsim formatla - Türkçe karakterler destekli
  String _formatName(String name) {
    if (name.isEmpty) return '';

    return name
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) {
      if (word.length <= 1) return word.toUpperCase();

      // Türkçe karakter desteği
      String firstChar = word[0].toUpperCase();
      String restChars = word.substring(1).toLowerCase();

      // Türkçe karakter dönüşümleri
      firstChar = firstChar.replaceAll('i', 'İ').replaceAll('ı', 'I');

      restChars = restChars.replaceAll('I', 'ı').replaceAll('İ', 'i');

      return firstChar + restChars;
    }).join(' ');
  }

  // HTML entity decode işlemi
  String _decodeHtmlEntities(String text) {
    String decoded = text;

    // Yaygın HTML entity'leri decode et
    final entityMap = {
      '&#39;': "'",
      '&quot;': '"',
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&nbsp;': ' ',
      '&#x27;': "'",
      '&#x2F;': '/',
      '&#x60;': '`',
      '&#x3D;': '=',
    };

    entityMap.forEach((entity, replacement) {
      decoded = decoded.replaceAll(entity, replacement);
    });

    // Numeric entities (&#number;) decode et
    decoded = decoded.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (match) {
        try {
          int charCode = int.parse(match.group(1)!);
          return String.fromCharCode(charCode);
        } catch (e) {
          return match.group(0)!; // Decode edilemezse olduğu gibi bırak
        }
      },
    );

    // Hex numeric entities (&#xhex;) decode et
    decoded = decoded.replaceAllMapped(
      RegExp(r'&#x([0-9a-fA-F]+);'),
      (match) {
        try {
          int charCode = int.parse(match.group(1)!, radix: 16);
          return String.fromCharCode(charCode);
        } catch (e) {
          return match.group(0)!; // Decode edilemezse olduğu gibi bırak
        }
      },
    );

    return decoded;
  }

  // Servisi temizle
  void dispose() {
    _barcodeScanner.close();
  }
}
