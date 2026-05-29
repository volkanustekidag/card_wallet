import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/qr_iban_scanner_service.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_bank_detector.dart';
import 'package:wallet_app/feature/add_iban_card/controller/add_iban_card_controller.dart';
import 'package:wallet_app/feature/add_iban_card/widgets/iban_text_field.dart';
import 'package:wallet_app/feature/add_credit_card/widgets/text_field_card.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/widgets/notes_and_tags_section.dart';

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

    // Controller'ları başlat
    cardHolderController = TextEditingController();
    swiftCodeController = TextEditingController();
    bankNameController = TextEditingController();

    // Initial değerleri set et
    _updateTextFields();

    // currentCard değişikliklerini dinle
    ever(controller.currentCard, (_) => _updateTextFields());

    // IBAN değiştiğinde bank-code'undan banka adını otomatik doldur.
    // Kullanıcı isterse bank field'ı manuel olarak değiştirebilir; bir
    // sonraki IBAN değişikliği yine üzerine yazar.
    widget.ibanController.addListener(_autoFillBankFromIban);
  }

  void _autoFillBankFromIban() {
    final iban = widget.ibanController.text;
    final detected = CardBankDetector.detectFromIban(iban);
    if (detected != null && bankNameController.text != detected) {
      bankNameController.text = detected;
      controller.updateCardField('bankName', detected);
    }
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
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'scanQR'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading:
                    Icon(Icons.qr_code_scanner, color: colorScheme.primary),
                title: Text('scanQR'.tr()),
                subtitle: Text('scanQRSubtitle'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  _scanQRForIban();
                },
              ),
              ListTile(
                leading:
                    Icon(Icons.photo_library, color: colorScheme.secondary),
                title: Text('chooseFromGallery'.tr()),
                subtitle: Text('chooseFromGallerySubtitle'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  _scanQRFromGallery();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleQRButtonPressed() async {
    // QR scanner free for everyone — same logic as the credit card
    // scanner. The 2-card free cap is what funnels upgrades.
    _showQRScanOptions();
  }

  @override
  void dispose() {
    widget.ibanController.removeListener(_autoFillBankFromIban);
    cardHolderController.dispose();
    swiftCodeController.dispose();
    bankNameController.dispose();
    _qrScannerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ibanFlowLead'.tr(),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w400,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 20),
        IbanTextField(
          ibanController: widget.ibanController,
          focusNode: widget.focusNode,
          cameras: widget.cameras,
        ),
        const SizedBox(height: 12),
        _buildQrButton(context),
        const SizedBox(height: 28),
        _buildSectionLabel(context, 'accountInfo'.tr()),
        const SizedBox(height: 12),
        TextFieldCard(
          controller: cardHolderController,
          label: "hName".tr(),
          maxLength: 32,
          onChanged: (val) {
            controller.updateCardField("cardHolder", val);
          },
          iconData: Icons.person_outline_rounded,
          hintText: "XXXXXX XXXXXX",
        ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 16),
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
        const SizedBox(height: 24),
        NotesAndTagsSection(
          initialNotes: controller.currentCard.value.notes,
          initialTags: controller.currentCard.value.tags,
          onNotesChanged: (val) =>
              controller.updateCardField('notes', val),
          onTagsChanged: (val) => controller.updateCardField('tags', val),
        ),
        const SizedBox(height: 28),
        _buildSecurityMessage(context),
      ],
    );
  }

  Widget _buildQrButton(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return OutlinedButton(
      onPressed: _isScanning ? null : _handleQRButtonPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.35),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.4),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        foregroundColor: accent,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_scanner, color: accent, size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              _isScanning ? 'scanInProgress'.tr() : 'scanQROptional'.tr(),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: accent,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (_isScanning) ...[
            const SizedBox(width: 10),
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSecurityMessage(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'ibanSecurityMessage'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
