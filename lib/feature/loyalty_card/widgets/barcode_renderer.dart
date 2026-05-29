import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Renders a loyalty card's barcode in whatever format the user originally
/// scanned. If the data can't be encoded in the selected format (e.g. EAN_13
/// needs exactly 13 digits but the saved value is shorter), shows a blank
/// barcode-shaped placeholder instead of throwing or falling back to text —
/// the user can still see the format is "barcode" and edit the value.
class BarcodeRenderer extends StatelessWidget {
  final String data;
  final String format;
  final double qrSize;
  final double barcodeHeight;

  const BarcodeRenderer({
    Key? key,
    required this.data,
    required this.format,
    this.qrSize = 240,
    this.barcodeHeight = 120,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (format == 'QR_CODE') {
      return QrImageView(
        data: data,
        size: qrSize,
        backgroundColor: Colors.white,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
      );
    }

    final barcode = _resolveBarcode(format);
    if (barcode == null) {
      return _blankBarcode();
    }

    return SizedBox(
      height: barcodeHeight,
      child: BarcodeWidget(
        data: data,
        barcode: barcode,
        drawText: false,
        color: Colors.black,
        backgroundColor: Colors.white,
        errorBuilder: (context, error) => _blankBarcode(),
      ),
    );
  }

  /// Blank space sized like a barcode would be — keeps the layout stable
  /// when the data can't be encoded and avoids the red `BarcodeWidget`
  /// error box. Background stays white so the surrounding card chrome
  /// (label, padding) still reads as a "barcode area".
  Widget _blankBarcode() {
    return Container(
      height: barcodeHeight,
      color: Colors.white,
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
