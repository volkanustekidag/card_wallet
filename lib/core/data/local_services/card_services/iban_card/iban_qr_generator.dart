import 'dart:convert';

/// Banking Standard IBAN QR Code Generator for Flutter
/// Compliant with EPC QR Code, ISO 20022, and regional banking standards
class IBANQRGenerator {
  /// IBAN country codes and their lengths
  static const Map<String, int> _ibanLengths = {
    'AD': 24,
    'AE': 23,
    'AL': 28,
    'AT': 20,
    'AZ': 28,
    'BA': 20,
    'BE': 16,
    'BG': 22,
    'BH': 22,
    'BR': 29,
    'BY': 28,
    'CH': 21,
    'CR': 22,
    'CY': 28,
    'CZ': 24,
    'DE': 22,
    'DK': 18,
    'DO': 28,
    'EE': 20,
    'EG': 29,
    'ES': 24,
    'FI': 18,
    'FO': 18,
    'FR': 27,
    'GB': 22,
    'GE': 22,
    'GI': 23,
    'GL': 18,
    'GR': 27,
    'GT': 28,
    'HR': 21,
    'HU': 28,
    'IE': 22,
    'IL': 23,
    'IS': 26,
    'IT': 27,
    'JO': 30,
    'KW': 30,
    'KZ': 20,
    'LB': 28,
    'LC': 32,
    'LI': 21,
    'LT': 20,
    'LU': 20,
    'LV': 21,
    'MC': 27,
    'MD': 24,
    'ME': 22,
    'MK': 19,
    'MR': 27,
    'MT': 31,
    'MU': 30,
    'NL': 18,
    'NO': 15,
    'PK': 24,
    'PL': 28,
    'PS': 29,
    'PT': 25,
    'QA': 29,
    'RO': 24,
    'RS': 22,
    'SA': 24,
    'SE': 24,
    'SI': 19,
    'SK': 24,
    'SM': 27,
    'TN': 24,
    'TR': 26,
    'UA': 29,
    'VG': 24,
    'XK': 20
  };

  /// Turkish bank codes (for TR-KAREKOD)
  static const Map<String, String> _turkishBankCodes = {
    '0001': 'Türkiye Cumhuriyet Merkez Bankası',
    '0010': 'Türkiye Cumhuriyeti Ziraat Bankası',
    '0012': 'Türkiye Halk Bankası',
    '0015': 'Türkiye Vakıflar Bankası',
    '0032': 'Türk Ekonomi Bankası',
    '0046': 'Akbank',
    '0059': 'Şekerbank',
    '0062': 'Türkiye Garanti Bankası',
    '0064': 'Türkiye İş Bankası',
    '0067': 'Yapı ve Kredi Bankası',
    '0099': 'İNG Bank',
    '0103': 'Türk Eximbank',
    '0111': 'Fibabanka',
    '0124': 'Türkiye Kalkınma Bankası',
    '0134': 'Denizbank',
    '0135': 'Anadolubank',
    '0143': 'HSBC Bank',
    '0146': 'Odea Bank',
    '0149': 'ICBC Turkey Bank',
    '0203': 'QNB Finansbank',
    '0205': 'Türkiye Finans Katılım Bankası',
    '0206': 'Türkiye Emlak Katılım Bankası',
    '0208': 'Türkiye Cumhuriyeti Ziraat Katılım Bankası',
    '0209': 'Albaraka Türk Katılım Bankası',
    '0210': 'Kuveyt Türk Katılım Bankası',
    '0211': 'Vakıf Katılım Bankası',
  };

  /// QR Code formats
  static const String formatAuto = 'auto';
  static const String formatEPC = 'epc';
  static const String formatTRKareKod = 'trKareKod';
  static const String formatTRFast = 'trFast';
  static const String formatISO20022 = 'iso20022';

  /// Payment data model
  static Map<String, dynamic> createPaymentData({
    required String iban,
    required String beneficiaryName,
    String? beneficiaryAddress,
    double? amount,
    String currency = 'EUR',
    String? reference,
    String? description,
    String? email,
    String? phone,
    String? bic,
    String? purposeCode,
  }) {
    return {
      'iban': iban,
      'beneficiaryName': beneficiaryName,
      'beneficiaryAddress': beneficiaryAddress ?? '',
      'amount': amount,
      'currency': currency,
      'reference': reference ?? '',
      'description': description ?? '',
      'email': email ?? '',
      'phone': phone ?? '',
      'bic': bic ?? '',
      'purposeCode': purposeCode ?? '',
    };
  }

  /// Validate IBAN with enhanced checking
  static bool validateIBAN(String iban) {
    if (iban.isEmpty) return false;

    iban = iban.replaceAll(RegExp(r'\s'), '').toUpperCase();

    if (iban.length < 15 || iban.length > 34) return false;

    final countryCode = iban.substring(0, 2);
    if (!_ibanLengths.containsKey(countryCode)) return false;
    if (iban.length != _ibanLengths[countryCode]) return false;

    // Check if all characters are alphanumeric
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(iban)) return false;

    // IBAN mod-97 check
    final rearranged = iban.substring(4) + iban.substring(0, 4);
    final numericString = rearranged.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => (match.group(0)!.codeUnitAt(0) - 55).toString(),
    );

    return _mod97(numericString) == 1;
  }

  /// Calculate mod 97 for large numbers
  static int _mod97(String numericString) {
    String remainder = '';
    for (int i = 0; i < numericString.length; i++) {
      remainder += numericString[i];
      if (remainder.length >= 9) {
        remainder = (int.parse(remainder) % 97).toString();
      }
    }
    return int.parse(remainder) % 97;
  }

  /// Validate BIC code
  static bool validateBIC(String bic) {
    if (bic.isEmpty) return true; // BIC is optional
    bic = bic.toUpperCase();
    // BIC should be 8 or 11 characters: 4 bank code + 2 country + 2 location [+ 3 branch]
    return RegExp(r'^[A-Z]{4}[A-Z]{2}[A-Z0-9]{2}([A-Z0-9]{3})?$').hasMatch(bic);
  }

  /// Generate EPC QR Code data (European Central Bank Standard)
  /// Compliant with EPC069-12 Technical Specification
  static String _generateEPCQRData(Map<String, dynamic> data) {
    final iban = data['iban'] as String;
    final beneficiaryName = data['beneficiaryName'] as String;
    final amount = data['amount'] as double?;
    final reference = data['reference'] as String? ?? '';
    final description = data['description'] as String? ?? '';
    final bic = data['bic'] as String? ?? '';
    final currency = (data['currency'] as String? ?? 'EUR').toUpperCase();

    // EPC QR Code fields according to EPC069-12 v2.1
    final epcData = [
      'BCD', // Service Tag (mandatory)
      '002', // Version (002 for v2.1)
      '1', // Character set (1=UTF-8)
      'SCT', // Identification (SCT=SEPA Credit Transfer)
      bic.isNotEmpty ? bic : '', // BIC (optional but recommended)
      _truncateString(beneficiaryName, 70), // Beneficiary name (max 70 chars)
      iban, // Beneficiary account (IBAN)
      amount != null && amount > 0
          ? '$currency${amount.toStringAsFixed(2)}'
          : '', // Amount (optional, format: EUR123.45)
      '', // Purpose (optional, 3 chars)
      _truncateString(reference, 35), // Structured reference (max 35 chars)
      _truncateString(
          description, 140), // Unstructured remittance info (max 140 chars)
    ];

    return epcData.join('\n');
  }

  /// Generate Turkey TR-KAREKOD format (TCMB Standard)
  /// Compliant with Turkish Central Bank QR Code Standard (TCMB-BKM)
  static String _generateTRKareKodData(Map<String, dynamic> data) {
    final iban = data['iban'] as String;
    final beneficiaryName = data['beneficiaryName'] as String;
    final amount = data['amount'] as double?;
    final reference = data['reference'] as String? ?? '';
    final description = data['description'] as String? ?? '';

    // Extract bank code from Turkish IBAN (positions 4-7)
    final bankCode = iban.substring(4, 8);
    final bankName = _turkishBankCodes[bankCode] ?? 'Unknown Bank';

    // TR-KAREKOD Official Format (TCMB Standard)
    // Based on EMVCo QR Code Specification with Turkish extensions
    final qrFields = <String>[];
    
    // Payload Format Indicator (ID: 00) - Always "01"
    qrFields.add('000201');
    
    // Point of Initiation Method (ID: 01) - "11" for static, "12" for dynamic
    qrFields.add('010211');
    
    // Merchant Account Information (ID: 26-51) - Using 51 for Turkey
    final merchantInfo = _buildMerchantInfo(iban, bankCode);
    qrFields.add('51${merchantInfo.length.toString().padLeft(2, '0')}$merchantInfo');
    
    // Transaction Currency (ID: 53) - "949" for TRY
    qrFields.add('5303949');
    
    // Transaction Amount (ID: 54) - Only if amount is specified
    if (amount != null && amount > 0) {
      final amountStr = amount.toStringAsFixed(2);
      qrFields.add('54${amountStr.length.toString().padLeft(2, '0')}$amountStr');
    }
    
    // Country Code (ID: 58) - "TR" for Turkey
    qrFields.add('5802TR');
    
    // Merchant Name (ID: 59) - Beneficiary name (max 25 chars)
    final merchantName = _truncateString(beneficiaryName, 25);
    qrFields.add('59${merchantName.length.toString().padLeft(2, '0')}$merchantName');
    
    // Additional Data Field Template (ID: 62)
    final additionalData = _buildAdditionalData(reference, description);
    if (additionalData.isNotEmpty) {
      qrFields.add('62${additionalData.length.toString().padLeft(2, '0')}$additionalData');
    }
    
    // Build the complete QR string
    final qrString = qrFields.join('');
    
    // Calculate CRC16 checksum (ID: 63)
    final crc = _calculateCRC16(qrString + '6304');
    final finalQR = qrString + '63' + '04' + crc.toRadixString(16).toUpperCase().padLeft(4, '0');
    
    return finalQR;
  }
  
  /// Build merchant account information for Turkish banks
  static String _buildMerchantInfo(String iban, String bankCode) {
    final fields = <String>[];
    
    // Globally Unique Identifier (ID: 00) - Turkish domain
    fields.add('0007tr.gov.tcmb');
    
    // Merchant Account Information (ID: 01) - IBAN
    fields.add('01${iban.length.toString().padLeft(2, '0')}$iban');
    
    // Bank Code (ID: 02)
    fields.add('02${bankCode.length.toString().padLeft(2, '0')}$bankCode');
    
    return fields.join('');
  }
  
  /// Build additional data field for reference and description
  static String _buildAdditionalData(String reference, String description) {
    final fields = <String>[];
    
    // Bill Number (ID: 01) - Reference
    if (reference.isNotEmpty) {
      final ref = _truncateString(reference, 25);
      fields.add('01${ref.length.toString().padLeft(2, '0')}$ref');
    }
    
    // Purpose of Transaction (ID: 08) - Description
    if (description.isNotEmpty) {
      final desc = _truncateString(description, 25);
      fields.add('08${desc.length.toString().padLeft(2, '0')}$desc');
    }
    
    return fields.join('');
  }
  
  /// Calculate CRC16 checksum for QR code validation
  static int _calculateCRC16(String data) {
    int crc = 0xFFFF;
    final bytes = data.codeUnits;
    
    for (int byte in bytes) {
      crc ^= byte << 8;
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = (crc << 1) ^ 0x1021;
        } else {
          crc = crc << 1;
        }
        crc &= 0xFFFF;
      }
    }
    
    return crc;
  }

  /// Generate TR-FAST QR Code (Turkish Fast Payment System)
  /// Compliant with BKM Fast Payment Standard - EMVCo format
  static String _generateTRFastData(Map<String, dynamic> data) {
    final iban = data['iban'] as String;
    final beneficiaryName = data['beneficiaryName'] as String;
    final amount = data['amount'] as double?;
    final reference = data['reference'] as String? ?? '';
    final description = data['description'] as String? ?? '';

    // Extract bank code from Turkish IBAN (positions 4-7)
    final bankCode = iban.substring(4, 8);

    // TR-FAST EMVCo QR Code Format (BKM Standard)
    final qrFields = <String>[];
    
    // Payload Format Indicator (ID: 00) - Always "01"
    qrFields.add('000201');
    
    // Point of Initiation Method (ID: 01) - "12" for dynamic (TR-FAST)
    qrFields.add('010212');
    
    // Merchant Account Information (ID: 26-51) - Using 50 for TR-FAST
    final fastInfo = _buildTRFastInfo(iban, bankCode, beneficiaryName);
    qrFields.add('50${fastInfo.length.toString().padLeft(2, '0')}$fastInfo');
    
    // Transaction Currency (ID: 53) - "949" for TRY
    qrFields.add('5303949');
    
    // Transaction Amount (ID: 54) - Mandatory for TR-FAST
    if (amount != null && amount > 0) {
      final amountStr = amount.toStringAsFixed(2);
      qrFields.add('54${amountStr.length.toString().padLeft(2, '0')}$amountStr');
    }
    
    // Country Code (ID: 58) - "TR" for Turkey
    qrFields.add('5802TR');
    
    // Merchant Name (ID: 59) - Beneficiary name (max 25 chars)
    final merchantName = _truncateString(beneficiaryName, 25);
    qrFields.add('59${merchantName.length.toString().padLeft(2, '0')}$merchantName');
    
    // Merchant City (ID: 60) - Optional
    qrFields.add('6007TURKIYE');
    
    // Additional Data Field Template (ID: 62) - Enhanced for TR-FAST
    final additionalData = _buildTRFastAdditionalData(reference, description);
    if (additionalData.isNotEmpty) {
      qrFields.add('62${additionalData.length.toString().padLeft(2, '0')}$additionalData');
    }
    
    // Build the complete QR string
    final qrString = qrFields.join('');
    
    // Calculate CRC16 checksum (ID: 63)
    final crc = _calculateCRC16(qrString + '6304');
    final finalQR = qrString + '63' + '04' + crc.toRadixString(16).toUpperCase().padLeft(4, '0');
    
    return finalQR;
  }
  
  /// Build TR-FAST specific merchant account information
  static String _buildTRFastInfo(String iban, String bankCode, String beneficiaryName) {
    final fields = <String>[];
    
    // Globally Unique Identifier (ID: 00) - TR-FAST domain
    fields.add('0011tr.gov.fast');
    
    // Merchant Account Information (ID: 01) - IBAN
    fields.add('01${iban.length.toString().padLeft(2, '0')}$iban');
    
    // Bank Code (ID: 02)
    fields.add('02${bankCode.length.toString().padLeft(2, '0')}$bankCode');
    
    // Service Type (ID: 03) - "FAST" for instant payment
    fields.add('0304FAST');
    
    return fields.join('');
  }
  
  /// Build TR-FAST specific additional data
  static String _buildTRFastAdditionalData(String reference, String description) {
    final fields = <String>[];
    
    // Bill Number (ID: 01) - Reference/Invoice number
    if (reference.isNotEmpty) {
      final ref = _truncateString(reference, 25);
      fields.add('01${ref.length.toString().padLeft(2, '0')}$ref');
    }
    
    // Purpose of Transaction (ID: 08) - Description
    if (description.isNotEmpty) {
      final desc = _truncateString(description, 25);
      fields.add('08${desc.length.toString().padLeft(2, '0')}$desc');
    }
    
    // Payment System (ID: 09) - TR-FAST identifier
    fields.add('0906TRFAST');
    
    return fields.join('');
  }

  /// Generate ISO 20022 compliant QR Code
  /// Based on ISO 20022 Credit Transfer messages
  static String _generateISO20022Data(Map<String, dynamic> data) {
    final iban = data['iban'] as String;
    final beneficiaryName = data['beneficiaryName'] as String;
    final amount = data['amount'] as double?;
    final reference = data['reference'] as String? ?? '';
    final description = data['description'] as String? ?? '';
    final bic = data['bic'] as String? ?? '';
    final currency = (data['currency'] as String? ?? 'EUR').toUpperCase();

    // ISO 20022 pain.001 (Customer Credit Transfer Initiation) structure
    final iso20022Data = {
      'GrpHdr': {
        'MsgId': 'QR-${DateTime.now().millisecondsSinceEpoch}',
        'CreDtTm': DateTime.now().toIso8601String(),
        'NbOfTxs': '1',
        'InitgPty': {'Nm': 'QR Generator'}
      },
      'PmtInf': {
        'PmtInfId': 'QR-PMT-${DateTime.now().millisecondsSinceEpoch}',
        'PmtMtd': 'TRF',
        'ReqdExctnDt': DateTime.now().toIso8601String().split('T')[0],
        'Dbtr': {'Nm': 'QR Initiator'},
        'CdtTrfTxInf': {
          'PmtId': {
            'InstrId': 'QR-${DateTime.now().millisecondsSinceEpoch}',
            'EndToEndId': reference.isNotEmpty ? reference : 'NOTPROVIDED'
          },
          'Amt': amount != null
              ? {
                  'InstdAmt': {
                    'Ccy': currency,
                    'value': amount.toStringAsFixed(2)
                  }
                }
              : null,
          'Cdtr': {'Nm': beneficiaryName},
          'CdtrAcct': {
            'Id': {'IBAN': iban}
          },
          'CdtrAgt': bic.isNotEmpty
              ? {
                  'FinInstnId': {'BIC': bic}
                }
              : null,
          'RmtInf': description.isNotEmpty ? {'Ustrd': description} : null
        }
      }
    };

    return jsonEncode(iso20022Data);
  }

  /// Main QR code generation method
  static QRResult generateQRCode(
    Map<String, dynamic> inputData, {
    String format = 'auto',
  }) {
    try {
      // Validate input data
      final validation = _validateInput(inputData);
      if (!validation.isValid) {
        return QRResult.error(validation.errors);
      }

      final data = _sanitizeInput(inputData);
      String qrData;
      String actualFormat = format;

      // Determine format based on IBAN country and banking standards
      if (format == formatAuto) {
        final countryCode = (data['iban'] as String).substring(0, 2);

        if (countryCode == 'TR') {
          // For Turkish IBANs, use TR-KAREKOD as default (static QR)
          // TR-FAST is used for dynamic payments with amount > 0
          actualFormat = formatTRKareKod;
          
          // If amount is provided and > 0, use TR-FAST for instant payment
          if (data['amount'] != null && data['amount'] > 0) {
            actualFormat = formatTRFast;
          }
        } else if (_isEPCCountry(countryCode)) {
          // For SEPA countries, use EPC standard
          actualFormat = formatEPC;
        } else {
          // For other countries, use ISO 20022
          actualFormat = formatISO20022;
        }
      }

      // Generate QR code data according to banking standards
      switch (actualFormat) {
        case formatEPC:
          qrData = _generateEPCQRData(data);
          break;
        case formatTRKareKod:
          qrData = _generateTRKareKodData(data);
          break;
        case formatTRFast:
          qrData = _generateTRFastData(data);
          break;
        case formatISO20022:
          qrData = _generateISO20022Data(data);
          break;
        default:
          qrData = _generateEPCQRData(data); // Fallback to EPC
          break;
      }

      return QRResult.success(
        data: qrData,
        format: actualFormat,
        metadata: QRMetadata(
          country: (data['iban'] as String).substring(0, 2),
          beneficiary: data['beneficiaryName'] as String,
          amount: data['amount'] as double?,
          currency: data['currency'] as String? ?? 'EUR',
          generatedAt: DateTime.now(),
          bankCode: _extractBankCode(data['iban'] as String),
          standard: _getStandardName(actualFormat),
        ),
      );
    } catch (error) {
      return QRResult.error(['QR kod oluşturma hatası: $error']);
    }
  }

  /// Check if country is part of EPC (European Payments Council)
  static bool _isEPCCountry(String countryCode) {
    const epcCountries = [
      'AD',
      'AT',
      'BE',
      'BG',
      'CH',
      'CY',
      'CZ',
      'DE',
      'DK',
      'EE',
      'ES',
      'FI',
      'FR',
      'GB',
      'GR',
      'HR',
      'HU',
      'IE',
      'IS',
      'IT',
      'LI',
      'LT',
      'LU',
      'LV',
      'MC',
      'MT',
      'NL',
      'NO',
      'PL',
      'PT',
      'RO',
      'SE',
      'SI',
      'SK',
      'SM',
      'VA'
    ];
    return epcCountries.contains(countryCode);
  }

  /// Extract bank code from IBAN
  static String? _extractBankCode(String iban) {
    final countryCode = iban.substring(0, 2);
    if (countryCode == 'TR' && iban.length >= 8) {
      return iban.substring(4, 8); // Turkish bank code
    }
    return null;
  }

  /// Get standard name
  static String _getStandardName(String format) {
    switch (format) {
      case formatEPC:
        return 'EPC QR Code (SEPA)';
      case formatTRKareKod:
        return 'TR-KAREKOD (TCMB)';
      case formatTRFast:
        return 'TR-FAST (BKM)';
      case formatISO20022:
        return 'ISO 20022';
      default:
        return 'Unknown';
    }
  }

  /// Truncate string to specified length
  static String _truncateString(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength);
  }

  /// Enhanced input validation
  static ValidationResult _validateInput(Map<String, dynamic> data) {
    final errors = <String>[];

    // IBAN validation
    final iban = data['iban'] as String?;
    if (iban == null || iban.isEmpty) {
      errors.add('IBAN adresi gerekli');
    } else if (!validateIBAN(iban)) {
      errors.add(
          'Geçersiz IBAN adresi. Lütfen doğru IBAN formatını kontrol edin.');
    }

    // Beneficiary name validation
    final beneficiaryName = data['beneficiaryName'] as String?;
    if (beneficiaryName == null || beneficiaryName.isEmpty) {
      errors.add('Alıcı adı gerekli');
    } else if (beneficiaryName.length < 2) {
      errors.add('Alıcı adı en az 2 karakter olmalı');
    } else if (beneficiaryName.length > 70) {
      errors.add('Alıcı adı 70 karakteri geçemez');
    }

    // Amount validation
    final amount = data['amount'] as double?;
    if (amount != null) {
      if (amount <= 0) {
        errors.add('Miktar 0\'dan büyük olmalı');
      } else if (amount > 999999999.99) {
        errors.add('Miktar çok yüksek');
      }
    }

    // Currency validation
    final currency = data['currency'] as String?;
    if (currency != null && currency.isNotEmpty) {
      if (!RegExp(r'^[A-Z]{3}$').hasMatch(currency)) {
        errors.add('Para birimi 3 harfli ISO kodu olmalı (örn: EUR, USD, TRY)');
      }
    }

    // BIC validation
    final bic = data['bic'] as String? ?? '';
    if (bic.isNotEmpty && !validateBIC(bic)) {
      errors.add('Geçersiz BIC kodu');
    }

    // Reference validation
    final reference = data['reference'] as String? ?? '';
    if (reference.length > 35) {
      errors.add('Referans 35 karakteri geçemez');
    }

    // Description validation
    final description = data['description'] as String? ?? '';
    if (description.length > 140) {
      errors.add('Açıklama 140 karakteri geçemez');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Sanitize input data
  static Map<String, dynamic> _sanitizeInput(Map<String, dynamic> data) {
    return {
      'iban':
          (data['iban'] as String).replaceAll(RegExp(r'\s'), '').toUpperCase(),
      'beneficiaryName': (data['beneficiaryName'] as String).trim(),
      'beneficiaryAddress':
          (data['beneficiaryAddress'] as String? ?? '').trim(),
      'amount': data['amount'] as double?,
      'currency': (data['currency'] as String? ?? 'EUR').toUpperCase(),
      'reference': (data['reference'] as String? ?? '').trim(),
      'description': (data['description'] as String? ?? '').trim(),
      'email': (data['email'] as String? ?? '').trim().toLowerCase(),
      'phone': data['phone'] != null
          ? (data['phone'] as String).replaceAll(RegExp(r'\s'), '')
          : '',
      'bic': (data['bic'] as String? ?? '').toUpperCase(),
      'purposeCode': (data['purposeCode'] as String? ?? '').trim(),
    };
  }

  /// Get supported countries
  static List<String> getSupportedCountries() {
    return _ibanLengths.keys.toList()..sort();
  }

  /// Get IBAN length for country
  static int? getIBANLength(String countryCode) {
    return _ibanLengths[countryCode.toUpperCase()];
  }

  /// Get Turkish bank name by code
  static String? getTurkishBankName(String bankCode) {
    return _turkishBankCodes[bankCode];
  }

  /// Format IBAN with spaces for display
  static String formatIBANForDisplay(String iban) {
    iban = iban.replaceAll(RegExp(r'\s'), '').toUpperCase();
    return iban
        .replaceAllMapped(RegExp(r'(.{4})'), (match) => '${match.group(0)} ')
        .trim();
  }
}

/// Validation result class
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({required this.isValid, required this.errors});
}

/// QR generation result class
class QRResult {
  final bool success;
  final String? data;
  final String? format;
  final QRMetadata? metadata;
  final List<String>? errors;

  QRResult._({
    required this.success,
    this.data,
    this.format,
    this.metadata,
    this.errors,
  });

  factory QRResult.success({
    required String data,
    required String format,
    required QRMetadata metadata,
  }) {
    return QRResult._(
      success: true,
      data: data,
      format: format,
      metadata: metadata,
    );
  }

  factory QRResult.error(List<String> errors) {
    return QRResult._(
      success: false,
      errors: errors,
    );
  }
}

/// Enhanced QR metadata class
class QRMetadata {
  final String country;
  final String beneficiary;
  final double? amount;
  final String currency;
  final DateTime generatedAt;
  final String? bankCode;
  final String standard;

  QRMetadata({
    required this.country,
    required this.beneficiary,
    this.amount,
    required this.currency,
    required this.generatedAt,
    this.bankCode,
    required this.standard,
  });

  String get formattedAmount => amount != null
      ? '${amount!.toStringAsFixed(2)} $currency'
      : 'Belirtilmedi';

  String get bankName => bankCode != null
      ? IBANQRGenerator.getTurkishBankName(bankCode!) ?? 'Bilinmeyen Banka'
      : 'Belirtilmedi';
}

/// Example usage with banking standards compliance
class BankingCompliantExample {
  static void demonstrateUsage() {
    // Turkish IBAN example - Static QR (TR-KAREKOD format)
    final turkishStaticPayment = IBANQRGenerator.createPaymentData(
      iban: 'TR330006100519786457841326',
      beneficiaryName: 'Volkan Üstekidağ',
      currency: 'TRY',
      reference: 'STATIC-QR',
      description: 'Hesap bilgisi QR kodu',
    );

    final turkishStaticResult = IBANQRGenerator.generateQRCode(
      turkishStaticPayment,
      format: IBANQRGenerator.formatTRKareKod,
    );
    print('Turkish Static QR (${turkishStaticResult.metadata?.standard}): ${turkishStaticResult.data}');

    // Turkish IBAN example - Dynamic QR with amount (TR-FAST format)
    final turkishDynamicPayment = IBANQRGenerator.createPaymentData(
      iban: 'TR330006100519786457841326',
      beneficiaryName: 'Volkan Üstekidağ',
      amount: 150.00,
      currency: 'TRY',
      reference: 'INV-2024-001',
      description: 'Fatura ödemesi',
    );

    final turkishDynamicResult = IBANQRGenerator.generateQRCode(
      turkishDynamicPayment,
      format: IBANQRGenerator.formatTRFast,
    );
    print('Turkish Dynamic QR (${turkishDynamicResult.metadata?.standard}): ${turkishDynamicResult.data}');

    // Auto-detection example (will choose appropriate format)
    final autoPayment = IBANQRGenerator.createPaymentData(
      iban: 'TR330006100519786457841326',
      beneficiaryName: 'Volkan Üstekidağ',
      amount: 75.50,
      currency: 'TRY',
    );

    final autoResult = IBANQRGenerator.generateQRCode(autoPayment);
    print('Auto-detected QR (${autoResult.metadata?.standard}): ${autoResult.data}');

    // European IBAN example (EPC format)
    final europeanPayment = IBANQRGenerator.createPaymentData(
      iban: 'DE89370400440532013000',
      beneficiaryName: 'Max Mustermann',
      amount: 100.00,
      currency: 'EUR',
      reference: 'RF18539007547034',
      bic: 'COBADEFFXXX',
    );

    final europeanResult = IBANQRGenerator.generateQRCode(europeanPayment);
    print('European QR (${europeanResult.metadata?.standard}): ${europeanResult.data}');

    // Validation examples
    print('IBAN Valid: ${IBANQRGenerator.validateIBAN('TR330006100519786457841326')}');
    print('BIC Valid: ${IBANQRGenerator.validateBIC('COBADEFFXXX')}');
    print('Formatted IBAN: ${IBANQRGenerator.formatIBANForDisplay('TR330006100519786457841326')}');
    
    // Bank name lookup
    print('Bank Name: ${IBANQRGenerator.getTurkishBankName('0006')}');
  }
}
