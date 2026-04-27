import 'package:barcode_widget/barcode_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wallet_app/core/components/dialog/delete_dialog.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/router/getx_bindings.dart';
import 'package:wallet_app/feature/add_loyalty_card/add_loyalty_card_page.dart';
import 'package:wallet_app/feature/loyalty_card/controller/loyalty_card_controller.dart';

class LoyaltyCardDetailPage extends StatelessWidget {
  final LoyaltyCard card;
  const LoyaltyCardDetailPage({Key? key, required this.card}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          card.name,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.black),
            onPressed: () => _onEdit(),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                color: colorScheme.error),
            onPressed: () => _onDelete(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              if (card.brand != null && card.brand!.isNotEmpty)
                Text(
                  card.brand!,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: Colors.grey.shade300, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: _BarcodeRenderer(
                      data: card.barcode,
                      format: card.barcodeFormat,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SelectableText(
                _formatBarcodeText(card.barcode),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'increaseBrightnessHint'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: card.barcode));
                      HapticFeedback.lightImpact();
                      Get.context?.showSuccessSnackBar('copyInfo');
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: Text('copyBarcodeAction'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              if (card.notes != null && card.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    card.notes!,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatBarcodeText(String raw) {
    if (raw.length <= 4) return raw;
    final chars = raw.split('');
    final buffer = StringBuffer();
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(chars[i]);
    }
    return buffer.toString();
  }

  void _onEdit() {
    Get.off(
      () => AddLoyaltyCardPage(card: card),
      binding: AddLoyaltyCardBindings(),
    );
  }

  void _onDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => CustomDialog(
        title: 'deleteCard'.tr(),
        content: 'deleteDataMessage'.tr(),
        onConfirm: () async {
          if (Get.isRegistered<LoyaltyCardController>()) {
            await Get.find<LoyaltyCardController>().removeLoyaltyCard(card);
          }
          Get.back();
        },
      ),
    );
  }
}

class _BarcodeRenderer extends StatelessWidget {
  final String data;
  final String format;
  const _BarcodeRenderer({required this.data, required this.format});

  @override
  Widget build(BuildContext context) {
    if (format == 'QR_CODE') {
      return QrImageView(
        data: data,
        size: 240,
        backgroundColor: Colors.white,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
      );
    }

    final barcode = _resolveBarcode(format);
    if (barcode == null) {
      return SelectableText(
        data,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 22,
          letterSpacing: 3,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: BarcodeWidget(
        data: data,
        barcode: barcode,
        drawText: false,
        color: Colors.black,
        backgroundColor: Colors.white,
      ),
    );
  }

  Barcode? _resolveBarcode(String format) {
    switch (format) {
      case 'CODE_128':
        return Barcode.code128();
      case 'CODE_39':
        return Barcode.code39();
      case 'EAN_13':
        return Barcode.ean13();
      case 'EAN_8':
        return Barcode.ean8();
      case 'UPC_A':
        return Barcode.upcA();
      case 'UPC_E':
        return Barcode.upcE();
      case 'ITF':
        return Barcode.itf();
      default:
        return null;
    }
  }
}
