import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/qr_iban_scanner_service.dart';
import 'package:wallet_app/feature/add_iban_card/controller/add_iban_card_controller.dart';
import 'package:wallet_app/feature/add_iban_card/widgets/iban_text_field.dart';
import 'package:wallet_app/feature/add_iban_card/widgets/text_field_card.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';

class IbanTextFieldForms extends StatefulWidget {
  final TextEditingController ibanController;
  final FocusNode focusNode;
  final List<CameraDescription> cameras;

  const IbanTextFieldForms({
    Key? key,
    required this.ibanController,
    required this.focusNode,
    required this.cameras,
  }) : super(key: key);

  @override
  State<IbanTextFieldForms> createState() => _IbanTextFieldFormsState();
}

class _IbanTextFieldFormsState extends State<IbanTextFieldForms> {
  late final AddIbanCardController controller;
  late final QRIbanScannerService _qrScannerService;
  late final PremiumController _premiumController;

  // TextEditingController'lar
  late final TextEditingController cardHolderController;
  late final TextEditingController swiftCodeController;
  late final TextEditingController bankNameController;

  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AddIbanCardController>();
    _qrScannerService = QRIbanScannerService();
    _premiumController = Get.find<PremiumController>();

    // Controller'ları başlat
    cardHolderController = TextEditingController();
    swiftCodeController = TextEditingController();
    bankNameController = TextEditingController();

    // Initial değerleri set et
    _updateTextFields();

    // currentCard değişikliklerini dinle
    ever(controller.currentCard, (_) => _updateTextFields());
  }

  void _updateTextFields() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final card = controller.currentCard.value;

        cardHolderController.text = card.cardHolder;
        widget.ibanController.text = card.iban;
        swiftCodeController.text = card.swiftCode;
        bankNameController.text = card.bankName;
      }
    });
  }

  // QR kod ile IBAN tarama
  Future<void> _scanQRForIban() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final scannedInfo = await _qrScannerService.scanQRForIban();

      if (scannedInfo != null) {
        // Taranan bilgileri form'a yansıt
        if (scannedInfo['iban']?.isNotEmpty == true) {
          widget.ibanController.text = scannedInfo['iban']!;
          controller.updateCardField("iban", scannedInfo['iban']!);
        }

        if (scannedInfo['cardHolder']?.isNotEmpty == true) {
          cardHolderController.text = scannedInfo['cardHolder']!;
          controller.updateCardField("cardHolder", scannedInfo['cardHolder']!);
        }

        if (scannedInfo['bankName']?.isNotEmpty == true) {
          bankNameController.text = scannedInfo['bankName']!;
          controller.updateCardField("bankName", scannedInfo['bankName']!);
        }

        if (scannedInfo['swiftCode']?.isNotEmpty == true) {
          swiftCodeController.text = scannedInfo['swiftCode']!;
          controller.updateCardField("swiftCode", scannedInfo['swiftCode']!);
        }

        context.showSuccessSnackBar('qrScanSuccess');
      }
    } catch (e) {
      context.showErrorSnackBar('Failed to scan QR code');
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  // Galeriden QR kod tarama
  Future<void> _scanQRFromGallery() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final scannedInfo = await _qrScannerService.scanQRFromGallery();

      if (scannedInfo != null) {
        // Taranan bilgileri form'a yansıt
        if (scannedInfo['iban']?.isNotEmpty == true) {
          widget.ibanController.text = scannedInfo['iban']!;
          controller.updateCardField("iban", scannedInfo['iban']!);
        }

        if (scannedInfo['cardHolder']?.isNotEmpty == true) {
          cardHolderController.text = scannedInfo['cardHolder']!;
          controller.updateCardField("cardHolder", scannedInfo['cardHolder']!);
        }

        if (scannedInfo['bankName']?.isNotEmpty == true) {
          bankNameController.text = scannedInfo['bankName']!;
          controller.updateCardField("bankName", scannedInfo['bankName']!);
        }

        if (scannedInfo['swiftCode']?.isNotEmpty == true) {
          swiftCodeController.text = scannedInfo['swiftCode']!;
          controller.updateCardField("swiftCode", scannedInfo['swiftCode']!);
        }

        context.showSuccessSnackBar('qrScanSuccess');
      }
    } catch (e) {
      context.showErrorSnackBar('Failed to scan QR code');
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  // QR tarama seçenekleri dialog'u
  void _showQRScanOptions() {
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
              'Scan QR Code for IBAN',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.qr_code_scanner, color: Colors.blue),
              title: Text('scanQR'.tr()),
              subtitle: Text('scanQRSubtitle'.tr()),
              onTap: () {
                Navigator.pop(context);
                _scanQRForIban();
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.green),
              title: Text('chooseFromGallery'.tr()),
              subtitle: Text('chooseFromGallerySubtitle'.tr()),
              onTap: () {
                Navigator.pop(context);
                _scanQRFromGallery();
              },
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _showPremiumRequiredDialog() async {
    final shouldUpgrade = await Get.dialog<bool>(
          AlertDialog(
            title: Text('premiumFeatureLockedTitle'.tr()),
            content: Text('premiumFeatureLockedDescription'.tr()),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text('maybeLater'.tr()),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                child: Text('goPremium'.tr()),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldUpgrade) {
      Get.toNamed('/premium');
    }
  }

  Future<void> _handleQRButtonPressed() async {
    if (!_premiumController.isPremium) {
      await _showPremiumRequiredDialog();
      return;
    }
    _showQRScanOptions();
  }

  @override
  void dispose() {
    cardHolderController.dispose();
    swiftCodeController.dispose();
    bankNameController.dispose();
    _qrScannerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // QR Tarama Butonu
              Obx(() {
                final isPremium = _premiumController.isPremium;
                return Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isScanning ? null : _handleQRButtonPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          !isPremium ? Colors.amber.shade600 : Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isPremium)
                          Row(
                            children: [
                              SizedBox(width: 8),
                              Icon(
                                Icons.workspace_premium,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        Spacer(),
                        if (_isScanning)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          Icon(
                            Icons.qr_code_scanner,
                            color: Colors.white,
                          ),
                        SizedBox(width: 8),
                        Text(
                          _isScanning
                              ? 'Scanning QR...'
                              : 'Scan QR Code for IBAN',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Spacer(),
                      ],
                    ),
                  ),
                );
              }),

              SizedBox(height: 16),
              TextFieldCard(
                controller: cardHolderController,
                label: "hName".tr(),
                maxLength: 32,
                onChanged: (val) {
                  controller.updateCardField("cardHolder", val);
                },
                iconData: Icons.person,
                hintText: "XXXXXX XXXXXX",
              ),
              IbanTextField(
                ibanController: widget.ibanController,
                focusNode: widget.focusNode,
                cameras: widget.cameras,
              ),
              TextFieldCard(
                controller: swiftCodeController,
                maxLength: 11,
                label: "sCode".tr(),
                onChanged: (val) {
                  controller.updateCardField("swiftCode", val);
                },
                iconData: Icons.numbers,
                hintText: "00000000",
              ),
              TextFieldCard(
                controller: bankNameController,
                maxLength: 24,
                label: "bName".tr(),
                onChanged: (val) {
                  controller.updateCardField("bankName", val);
                },
                iconData: Icons.account_balance_rounded,
                hintText: "XXXXXXX",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
