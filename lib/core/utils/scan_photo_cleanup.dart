import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Deletes the image file image_picker handed us once OCR / barcode
/// decoding is done, so a photo of a card doesn't linger in the app's
/// temp/cache directory.
///
/// Camera shots are always our own temp file. For gallery picks the plugin
/// returns a *copy* in the temp/cache directory; anything outside it is
/// treated as the user's original and left alone.
Future<void> deleteScanPhoto(
  XFile? photo, {
  required bool fromCamera,
  Future<Directory> Function() tempDirectory = getTemporaryDirectory,
}) async {
  if (photo == null) return;
  try {
    final file = File(photo.path);
    if (!fromCamera) {
      final temp = await tempDirectory();
      if (!file.absolute.path.startsWith(temp.absolute.path)) return;
    }
    if (await file.exists()) await file.delete();
  } catch (_) {
    // Best effort: the OS clears the temp dir eventually.
  }
}
