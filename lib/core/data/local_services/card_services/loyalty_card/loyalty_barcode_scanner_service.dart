import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Trans;
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/services/camera_permission_service.dart';

class LoyaltyBarcodeScanResult {
  final String rawValue;
  final String? format;
  const LoyaltyBarcodeScanResult({required this.rawValue, this.format});
}

/// Standalone scanner for loyalty cards. Kept separate from the IBAN QR
/// scanner so changes here cannot regress the IBAN flow.
class LoyaltyBarcodeScannerService {
  final ImagePicker _picker = ImagePicker();
  final BarcodeScanner _barcodeScanner = BarcodeScanner();

  Future<LoyaltyBarcodeScanResult?> scanFromCamera() async {
    if (!await CameraPermissionService.ensureGranted()) {
      return null;
    }
    return _pickAndDecode(ImageSource.camera);
  }

  Future<LoyaltyBarcodeScanResult?> scanFromGallery() async {
    return _pickAndDecode(ImageSource.gallery);
  }

  Future<LoyaltyBarcodeScanResult?> _pickAndDecode(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 100,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (photo == null) return null;

      final inputImage = InputImage.fromFilePath(photo.path);
      final barcodes = await _barcodeScanner.processImage(inputImage);
      if (barcodes.isEmpty) {
        Get.context?.showInfoSnackBar('loyaltyBarcodeNotFound'.tr());
        return null;
      }

      final Barcode first = barcodes.first;
      final raw = first.rawValue?.trim();
      if (raw == null || raw.isEmpty) {
        Get.context?.showInfoSnackBar('loyaltyBarcodeNotFound'.tr());
        return null;
      }

      return LoyaltyBarcodeScanResult(
        rawValue: raw,
        format: _mapFormat(first.format),
      );
    } catch (e) {
      debugPrint('Loyalty barcode scan error: $e');
      Get.context?.showErrorSnackBar('loyaltyBarcodeScanError'.tr());
      return null;
    }
  }

  /// Maps ML Kit's [BarcodeFormat] to the string codes used by
  /// `loyalty_barcode_formats.dart`. Returns null for formats not supported
  /// by the loyalty form (e.g. PDF417, Aztec, Data Matrix) so the caller can
  /// keep the user-selected default instead of overwriting it.
  String? _mapFormat(BarcodeFormat fmt) {
    switch (fmt) {
      case BarcodeFormat.code128:
        return 'CODE_128';
      case BarcodeFormat.code39:
        return 'CODE_39';
      case BarcodeFormat.ean13:
        return 'EAN_13';
      case BarcodeFormat.ean8:
        return 'EAN_8';
      case BarcodeFormat.upca:
        return 'UPC_A';
      case BarcodeFormat.upce:
        return 'UPC_E';
      case BarcodeFormat.qrCode:
        return 'QR_CODE';
      case BarcodeFormat.itf:
        return 'ITF';
      default:
        return null;
    }
  }

  void dispose() {
    _barcodeScanner.close();
  }
}
