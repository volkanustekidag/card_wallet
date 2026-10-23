import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wallet_app/core/brands/brand_catalog.dart';
import 'package:wallet_app/core/data/local_services/card_services/loyalty_card/loyalty_barcode_scanner_service.dart';
import 'package:wallet_app/core/services/app_lock_service.dart';
import 'package:wallet_app/core/utils/scan_photo_cleanup.dart';
import 'package:wallet_app/feature/import/importers.dart';
import 'package:wallet_app/feature/scanner/live_scanner_page.dart'
    show brandFromText;
import 'package:wallet_app/feature/scanner/scan_analyzer.dart';

/// Longest side kept from an imported screenshot.
const double _kMaxSide = 1600;

/// Cards from many photos at once: screenshots of another wallet app
/// (one card per screenshot) or photos of plastic cards.
abstract final class PhotoImport {
  /// Test seams: ML Kit and the photo picker need a device.
  @visibleForTesting
  static Future<List<XFile>> Function()? debugPick;
  @visibleForTesting
  static Future<List<ImportedCard>> Function(List<XFile>)? debugRead;

  /// Lets the user pick any number of images. Empty when cancelled.
  static Future<List<XFile>> pick() async {
    if (debugPick != null) return debugPick!();
    final files = await AppLockService.guard(() => ImagePicker().pickMultiImage(
        maxWidth: _kMaxSide, maxHeight: _kMaxSide, imageQuality: 85));
    return files;
  }

  /// Reads every image (barcode + printed text), calling [onProgress] with
  /// how many are done. The picked temp copies are deleted afterwards.
  static Future<List<ImportedCard>> read(
    List<XFile> files, {
    void Function(int done)? onProgress,
  }) async {
    if (debugRead != null) return debugRead!(files);
    final barcodes = BarcodeScanner();
    final text = TextRecognizer();
    final out = <ImportedCard>[];
    try {
      for (var i = 0; i < files.length; i++) {
        final f = files[i];
        try {
          final input = InputImage.fromFilePath(f.path);
          String? raw;
          String? format;
          for (final b in await barcodes.processImage(input)) {
            final hit = ScanAnalyzer.fromBarcode(
                b.rawValue ?? '',
                LoyaltyBarcodeScannerService.mapFormat(b.format),
                ScanMode.barcode);
            if (hit is LoyaltyHit) {
              raw = hit.raw;
              format = hit.format;
              break;
            }
          }
          final ocr = (await text.processImage(input)).text;
          out.add(cardFromScan(
            raw: raw,
            format: format,
            text: ocr,
            photo: await File(f.path).readAsBytes(),
            index: out.length + 1,
            fallbackName: (n) => 'cwCardN'.tr(args: ['$n']),
          ));
        } catch (_) {
          // An unreadable file is skipped; the others still import.
        } finally {
          await deleteScanPhoto(f, fromCamera: false);
          onProgress?.call(i + 1);
        }
      }
    } finally {
      await barcodes.close();
      await text.close();
    }
    return out;
  }

  /// One image's result: the brand named in its text (else its first
  /// readable line, else "Card [index]"), the barcode when one was found,
  /// otherwise the image itself as the card.
  static ImportedCard cardFromScan({
    required String? raw,
    required String? format,
    required String text,
    required Uint8List photo,
    required int index,
    String Function(int index)? fallbackName,
  }) {
    final BrandEntry? brand = brandFromText(text);
    final name = brand?.name ??
        firstNameLine(text) ??
        (fallbackName?.call(index) ?? 'Card $index');
    final hasCode = raw != null && raw.trim().isNotEmpty && format != null;
    return ImportedCard(
      name: name,
      barcode: hasCode ? raw.trim() : '',
      format: hasCode ? format : 'CODE_128',
      color: brand?.color,
      photo: hasCode ? null : photo,
    );
  }

  /// A plausible card name from OCR text: the first short line that has
  /// letters and isn't a number, a date or app chrome.
  static String? firstNameLine(String text) {
    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.length < 2 || line.length > 28) continue;
      final letters = RegExp(r'\p{L}', unicode: true).allMatches(line).length;
      if (letters < 2 || letters < line.length / 2) continue;
      if (RegExp(r'^\d{1,2}[:.]\d{2}').hasMatch(line)) continue; // clock
      return line;
    }
    return null;
  }
}
