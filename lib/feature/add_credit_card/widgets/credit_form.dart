import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;

import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/constants/paddings.dart';
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_scanner_service.dart';
import 'package:wallet_app/feature/add_credit_card/controller/add_credit_card_controller.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_number_formatter.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_valid_thru_formatter.dart';
import 'package:wallet_app/feature/add_credit_card/widgets/colors_list_view.dart';
import 'package:wallet_app/feature/add_credit_card/widgets/text_field_card.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_bank_detector.dart';
import 'package:wallet_app/feature/add_credit_card/utils/upper_case_formatter.dart';

class CreditTextFieldForms extends StatefulWidget {
  const CreditTextFieldForms({Key? key}) : super(key: key);

  @override
  State<CreditTextFieldForms> createState() => _CreditTextFieldFormsState();
}

class _CreditTextFieldFormsState extends State<CreditTextFieldForms> {
  late final AddCreditCardController controller;
  late final CreditCardScannerService _scannerService;
  late final PremiumController _premiumController;

  // TextEditingController'lar
  late final TextEditingController bankNameController;
  late final TextEditingController cardNumberController;
  late final TextEditingController cardHolderController;
  late final TextEditingController expirationController;
  late final TextEditingController cvcController;

  bool _isScanning = false;
  bool _bankDetectedFromNumber = false;
  bool _manualBankEditEnabled = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AddCreditCardController>();
    _scannerService = CreditCardScannerService();
    _premiumController = Get.find<PremiumController>();

    // Controller'ları başlat
    bankNameController = TextEditingController();
    cardNumberController = TextEditingController();
    cardHolderController = TextEditingController();
    expirationController = TextEditingController();
    cvcController = TextEditingController();

    // Initial değerleri set et
    _updateTextFields();

    // currentCard değişikliklerini dinle
    ever(controller.currentCard, (_) => _updateTextFields());
  }

  void _updateTextFields() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final card = controller.currentCard.value;

        bankNameController.text = card.bankName;
        cardNumberController.text = card.creditCardNumber;
        cardHolderController.text = card.cardHolder;
        expirationController.text = card.expirationDate;
        cvcController.text = card.cvc2;
        final detected = CardBankDetector.detect(card.creditCardNumber);
        setState(() {
          _bankDetectedFromNumber = !_manualBankEditEnabled &&
              detected != null &&
              detected == card.bankName;
        });
      }
    });
  }

  // Kamera ile kart tarama
  Future<void> _scanCreditCard() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final scannedInfo = await _scannerService.scanCreditCard();

      if (scannedInfo != null) {
        // Taranan bilgileri form'a yansıt
        if (scannedInfo['cardNumber']?.isNotEmpty == true) {
          cardNumberController.text = scannedInfo['cardNumber']!;
          controller.updateCardField(
              "creditCardNumber", scannedInfo['cardNumber']!);
        }

        if (scannedInfo['expiryDate']?.isNotEmpty == true) {
          expirationController.text = scannedInfo['expiryDate']!;
          controller.updateCardField(
              "expirationDate", scannedInfo['expiryDate']!);
        }

        if (scannedInfo['cardHolder']?.isNotEmpty == true) {
          cardHolderController.text = scannedInfo['cardHolder']!;
          controller.updateCardField("cardHolder", scannedInfo['cardHolder']!);
        }

        context.showSuccessSnackBar('creditCardScannedSuccessfully');
      }
    } catch (e) {
      context.showErrorSnackBar('failedToScanCreditCard');
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  // Galeriden fotoğraf seçme
  Future<void> _scanFromGallery() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final scannedInfo = await _scannerService.scanFromGallery();

      if (scannedInfo != null) {
        // Taranan bilgileri form'a yansıt
        if (scannedInfo['cardNumber']?.isNotEmpty == true) {
          cardNumberController.text = scannedInfo['cardNumber']!;
          controller.updateCardField(
              "creditCardNumber", scannedInfo['cardNumber']!);
        }

        if (scannedInfo['expiryDate']?.isNotEmpty == true) {
          expirationController.text = scannedInfo['expiryDate']!;
          controller.updateCardField(
              "expirationDate", scannedInfo['expiryDate']!);
        }

        if (scannedInfo['cardHolder']?.isNotEmpty == true) {
          cardHolderController.text = scannedInfo['cardHolder']!;
          controller.updateCardField("cardHolder", scannedInfo['cardHolder']!);
        }

        context.showSuccessSnackBar('creditCardScannedSuccessfully');
      }
    } catch (e) {
      context.showErrorSnackBar('failedToScanCreditCard');
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  // Tarama seçenekleri dialog'u
  void _showScanOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'scanCreditCard'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.camera_alt, color: Colors.blue),
              title: Text('takePhoto'.tr()),
              subtitle: Text('takePhotoSubtitle'.tr()),
              onTap: () {
                Navigator.pop(context);
                _scanCreditCard();
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.green),
              title: Text('choosePhotoFromGallery'.tr()),
              subtitle: Text('choosePhotoSubtitle'.tr()),
              onTap: () {
                Navigator.pop(context);
                _scanFromGallery();
              },
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _handleScanButtonPressed() {
    if (!_premiumController.isPremium) {
      Get.toNamed('/premium');
      return;
    }
    _showScanOptions();
  }

  @override
  void dispose() {
    bankNameController.dispose();
    cardNumberController.dispose();
    cardHolderController.dispose();
    expirationController.dispose();
    cvcController.dispose();
    _scannerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const PaddingConstants.normal(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScanButton(theme),
          const SizedBox(height: 24),
          _buildBankField(context),
          const SizedBox(height: 20),
          TextFieldCard(
            controller: cardNumberController,
            maxLength: 19,
            onChanged: _onCardNumberChanged,
            label: "cardNumberLabel".tr(),
            hintText: "0000 0000 0000 0000",
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CardNumberFormatter(),
            ],
            iconData: Icons.credit_card_rounded,
            textInputType: TextInputType.number,
            textStyle: TextStyle(fontFamily: 'Poppins', 
              fontSize: 18,
              letterSpacing: 1.5,
              color: theme.colorScheme.onSurface,
            ),
            emphasize: true,
          ),
          const SizedBox(height: 16),
          TextFieldCard(
            controller: cardHolderController,
            maxLength: 24,
            onChanged: (val) {
              final upper = val.toUpperCase();
              if (cardHolderController.text != upper) {
                cardHolderController.value = TextEditingValue(
                  text: upper,
                  selection: TextSelection.collapsed(offset: upper.length),
                );
              }
              controller.updateCardField("cardHolder", upper);
            },
            label: "cardholderLabel".tr(),
            hintText: "cardHolderPlaceholder".tr(),
            inputFormatters: [UpperCaseTextFormatter()],
            iconData: Icons.person_outline,
            textInputType: TextInputType.name,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextFieldCard(
                    controller: expirationController,
                    maxLength: 7,
                    onChanged: (val) {
                      controller.updateCardField("expirationDate", val);
                    },
                    label: "expiryLabel".tr(),
                    hintText: "MM / YY",
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[\d\s/]'),
                      ),
                      CardValidThruFormatter(),
                    ],
                    iconData: Icons.date_range,
                    textInputType: TextInputType.number,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 0),
                  child: TextFieldCard(
                    controller: cvcController,
                    maxLength: 3,
                    onChanged: (val) {
                      controller.updateCardField("cvc2", val);
                    },
                    label: "securityCodeLabel".tr(),
                    hintText: "•••",
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    iconData: Icons.lock_outline,
                    textInputType: TextInputType.number,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 24),
          _buildColorPickerSection(theme),
          const SizedBox(height: 24),
          Text(
            "secureStorageInfo".tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: _withOpacity(theme.colorScheme.onSurface, 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton(ThemeData theme) {
    final borderColor = _withOpacity(theme.colorScheme.primary, 0.2);
    return Obx(() {
      final isPremium = _premiumController.isPremium;
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _isScanning ? null : _handleScanButtonPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            side: BorderSide(color: borderColor),
            backgroundColor: _withOpacity(theme.colorScheme.primary, 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: !isPremium
              ? Icon(
                  Icons.workspace_premium,
                  color: Colors.amber[700],
                )
              : SizedBox.shrink(),
          label: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "scanCardOptional".tr(),
                style: TextStyle(fontFamily: 'Poppins', 
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              _isScanning
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : Icon(
                      Icons.document_scanner_outlined,
                      color: theme.colorScheme.primary,
                    ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildBankField(BuildContext context) {
    final isReadOnly = _bankDetectedFromNumber && !_manualBankEditEnabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFieldCard(
          controller: bankNameController,
          maxLength: 24,
          onChanged: (val) {
            if (val.isEmpty) {
              setState(() {
                _manualBankEditEnabled = false;
              });
            }
            controller.updateCardField("bankName", val);
          },
          label: "bName".tr(),
          hintText: "unknownBank".tr(),
          inputFormatters: null,
          iconData: Icons.account_balance_outlined,
          textInputType: TextInputType.text,
          readOnly: isReadOnly,
          helperText: isReadOnly ? "bankAutoDetected".tr() : null,
          suffixIcon: isReadOnly
              ? const Icon(Icons.lock_outline_rounded, size: 18)
              : null,
        ),
        if (isReadOnly)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _manualBankEditEnabled = true;
                  _bankDetectedFromNumber = false;
                });
              },
              child: Text(
                "editManually".tr(),
              ),
            ),
          ),
      ],
    );
  }

  void _onCardNumberChanged(String val) {
    controller.updateCardField("creditCardNumber", val);
    if (_manualBankEditEnabled) return;
    final detected = CardBankDetector.detect(val);
    if (detected != null) {
      setState(() {
        _bankDetectedFromNumber = true;
      });
      if (bankNameController.text != detected) {
        bankNameController.text = detected;
        controller.updateCardField("bankName", detected);
      }
    } else if (_bankDetectedFromNumber) {
      setState(() {
        _bankDetectedFromNumber = false;
      });
    }
  }

  Widget _buildColorPickerSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "cardColorOptional".tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "cardColorOptionalSubtitle".tr(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: _withOpacity(theme.colorScheme.onSurface, 0.6),
          ),
        ),
        const SizedBox(height: 12),
        const ColorsListView(),
      ],
    );
  }

  Color _withOpacity(Color color, double opacity) {
    final safeValue = opacity.clamp(0.0, 1.0);
    return color.withAlpha((safeValue * 255).round());
  }
}
