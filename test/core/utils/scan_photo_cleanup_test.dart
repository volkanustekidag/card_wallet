import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wallet_app/core/utils/scan_photo_cleanup.dart';

void main() {
  late Directory temp;
  late Directory gallery;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('cw_tmp');
    gallery = Directory.systemTemp.createTempSync('cw_gallery');
  });

  tearDown(() {
    temp.deleteSync(recursive: true);
    gallery.deleteSync(recursive: true);
  });

  File write(Directory dir, String name) =>
      File('${dir.path}/$name')..writeAsBytesSync([1, 2, 3]);

  test('camera photos are deleted', () async {
    final f = write(gallery, 'camera.jpg');
    await deleteScanPhoto(XFile(f.path),
        fromCamera: true, tempDirectory: () async => temp);
    expect(f.existsSync(), isFalse);
  });

  test('gallery copies in the temp dir are deleted', () async {
    final f = write(temp, 'image_picker_copy.jpg');
    await deleteScanPhoto(XFile(f.path),
        fromCamera: false, tempDirectory: () async => temp);
    expect(f.existsSync(), isFalse);
  });

  test('gallery originals outside the temp dir are kept', () async {
    final f = write(gallery, 'IMG_0001.jpg');
    await deleteScanPhoto(XFile(f.path),
        fromCamera: false, tempDirectory: () async => temp);
    expect(f.existsSync(), isTrue);
  });

  test('null and missing files are ignored', () async {
    await deleteScanPhoto(null, fromCamera: true);
    await deleteScanPhoto(XFile('${temp.path}/missing.jpg'),
        fromCamera: true, tempDirectory: () async => temp);
  });
}
