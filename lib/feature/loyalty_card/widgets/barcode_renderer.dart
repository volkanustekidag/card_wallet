import 'package:barcode_widget/barcode_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wallet_app/feature/loyalty_card/loyalty_barcode_validator.dart';

/// Renders a loyalty card's barcode in whatever format the user originally
/// scanned. If the data can't be encoded in the selected format (e.g. EAN_13
/// needs exactly 13 digits but the saved value is shorter) it says so in
/// the barcode area instead of throwing or drawing a blank box, and offers
/// [onChangeFormat] when the caller can open the edit screen.
class BarcodeRenderer extends StatelessWidget {
  final String data;
  final String format;
  final double qrSize;
  final double barcodeHeight;
  final VoidCallback? onChangeFormat;

  const BarcodeRenderer({
    Key? key,
    required this.data,
    required this.format,
    this.qrSize = 240,
    this.barcodeHeight = 120,
    this.onChangeFormat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final value = data.trim();

    if (format == 'QR_CODE' && value.isNotEmpty) {
      return QrImageView(
        data: value,
        size: qrSize,
        backgroundColor: Colors.white,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
      );
    }

    // Checked up front: BarcodeWidget's errorBuilder only covers `verify`,
    // while some values (odd-length ITF, empty data) pass it and throw while
    // painting, which lands in Crashlytics as BarcodeException.
    final barcode = LoyaltyBarcodeValidator.barcodeFor(format);
    if (barcode == null || !LoyaltyBarcodeValidator.canEncode(value, format)) {
      return _unrenderable(context);
    }

    return SizedBox(
      height: barcodeHeight,
      child: BarcodeWidget(
        data: value,
        barcode: barcode,
        drawText: false,
        color: Colors.black,
        backgroundColor: Colors.white,
        errorBuilder: (context, error) => _unrenderable(context),
      ),
    );
  }

  /// Same footprint as the barcode so the card layout stays stable; scales
  /// down to fit the small home tile.
  Widget _unrenderable(BuildContext context) {
    const ink = Color(0xFF5A5F6B);
    return SizedBox(
      height: format == 'QR_CODE' ? qrSize : barcodeHeight,
      child: ColoredBox(
        color: Colors.white,
        // Center fills a bounded parent and shrinks to the message in an
        // unbounded one, so this never asks for infinite width.
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 18,
                        color: ink,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'barcodeCannotRender'.tr(),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: ink,
                        ),
                      ),
                    ],
                  ),
                  if (onChangeFormat != null)
                    TextButton(
                      onPressed: onChangeFormat,
                      child: Text('barcodeChangeFormat'.tr()),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
