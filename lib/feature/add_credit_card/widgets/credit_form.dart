import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;

import 'package:sizer/sizer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/constants/paddings.dart';
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_scanner_service.dart';
import 'package:wallet_app/feature/add_credit_card/controller/add_credit_card_controller.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_number_formatter.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_valid_thru_formatter.dart';
import 'package:wallet_app/feature/add_credit_card/widgets/text_field_card.dart';

class CreditTextFieldForms extends StatefulWidget {
  const CreditTextFieldForms({Key? key}) : super(key: key);

  @override
  State<CreditTextFieldForms> createState() => _CreditTextFieldFormsState();
}

class _CreditTextFieldFormsState extends State<CreditTextFieldForms> {
  late final AddCreditCardController controller;
  late final CreditCardScannerService _scannerService;

  // TextEditingController'lar
  late final TextEditingController bankNameController;
  late final TextEditingController cardNumberController;
  late final TextEditingController cardHolderController;
  late final TextEditingController expirationController;
  late final TextEditingController cvcController;

  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AddCreditCardController>();
    _scannerService = CreditCardScannerService();

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

        Get.snackbar(
          'Success',
          'Credit card scanned successfully!',
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to scan credit card',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
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

        Get.snackbar(
          'Success',
          'Credit card scanned successfully!',
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to scan credit card',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
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
              'Scan Credit Card',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.camera_alt, color: Colors.blue),
              title: Text('Take Photo'),
              subtitle: Text('Use camera to scan card'),
              onTap: () {
                Navigator.pop(context);
                _scanCreditCard();
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.green),
              title: Text('Choose from Gallery'),
              subtitle: Text('Select existing photo'),
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
    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: const PaddingConstants.normal(),
          child: Column(
            children: [
              // Kamera Tarama Butonu
              Container(
                width: 90.w,
                margin: EdgeInsets.only(bottom: 16),
                child: ElevatedButton.icon(
                  onPressed: _isScanning ? null : _showScanOptions,
                  icon: _isScanning
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.camera_alt),
                  label: Text(_isScanning ? 'Scanning...' : 'Scan Credit Card'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              TextFieldCard(
                controller: bankNameController,
                maxLength: 16,
                onChanged: (val) {
                  controller.updateCardField("bankName", val);
                },
                label: "bName".tr(),
                hintText: "XX BANK",
                inputFormatters: null,
                iconData: Icons.account_balance_rounded,
                textInputType: null,
              ),
              SizedBox(height: 8),
              TextFieldCard(
                controller: cardNumberController,
                maxLength: 19,
                onChanged: (val) {
                  controller.updateCardField("creditCardNumber", val);
                },
                label: "cNum".tr(),
                hintText: "XXXX XXXX XXXX XXXX",
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CardNumberFormatter(),
                ],
                iconData: Icons.numbers,
                textInputType: TextInputType.number,
              ),
              SizedBox(height: 8),
              TextFieldCard(
                controller: cardHolderController,
                maxLength: 24,
                onChanged: (val) {
                  controller.updateCardField("cardHolder", val);
                },
                label: "hName".tr(),
                hintText: "XXX XXXX",
                inputFormatters: null,
                iconData: Icons.person,
                textInputType: null,
              ),
              SizedBox(
                width: 90.w,
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 5.0),
                        child: TextFieldCard(
                          controller: expirationController,
                          maxLength: 5,
                          onChanged: (val) {
                            controller.updateCardField("expirationDate", val);
                          },
                          label: "valid".tr(),
                          hintText: "XX/XX",
                          inputFormatters: [CardValidThruFormatter()],
                          iconData: Icons.date_range,
                          textInputType: TextInputType.number,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5.0),
                        child: TextFieldCard(
                          controller: cvcController,
                          maxLength: 3,
                          onChanged: (val) {
                            controller.updateCardField("cvc2", val);
                          },
                          label: "CVC2",
                          hintText: "XXX",
                          inputFormatters: null,
                          iconData: Icons.password,
                          textInputType: TextInputType.number,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
