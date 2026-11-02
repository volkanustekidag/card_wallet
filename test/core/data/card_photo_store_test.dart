import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/data/storage/card_photo_store.dart';

import '../../helpers/harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final h = Harness();
  final store = CardPhotoStore.instance;
  late Directory dir;
  final jpeg = Uint8List.fromList([
    0xFF, 0xD8, 0xFF, 0xE0, // JPEG magic
    ...List.generate(400, (i) => i % 251),
  ]);

  setUp(() async {
    await h.setUp();
    store.debugReset();
    dir = await Directory.systemTemp.createTemp('card_photos');
    store.debugDirectory = dir;
  });
  tearDown(() async {
    store.debugReset();
    await h.tearDown();
  });

  test('round-trips a photo and never writes it in the clear', () async {
    final id = await store.save(jpeg);
    final files = dir.listSync().whereType<File>().toList();
    expect(files, hasLength(1));
    final onDisk = files.single.readAsBytesSync();
    expect(onDisk.sublist(12, 16), isNot(jpeg.sublist(0, 4)));
    expect(onDisk.length, greaterThan(jpeg.length)); // nonce + GCM tag

    // Fresh process: key comes back from the Keychain, cache is empty.
    store
      ..debugReset()
      ..debugDirectory = dir;
    expect(await store.load(id), jpeg);
  });

  test('a modified file is rejected, not shown garbled', () async {
    final id = await store.save(jpeg);
    final f = dir.listSync().whereType<File>().single;
    final bytes = f.readAsBytesSync();
    bytes[40] ^= 0x01;
    f.writeAsBytesSync(bytes);
    store
      ..debugReset()
      ..debugDirectory = dir;
    expect(await store.load(id), isNull);
  });

  test('another key cannot read it', () async {
    final id = await store.save(jpeg);
    h.keychain.clear();
    store
      ..debugReset()
      ..debugDirectory = dir;
    expect(await store.load(id), isNull);
  });

  test('delete, keepOnly and bad ids', () async {
    final a = await store.save(jpeg);
    final b = await store.save(jpeg);
    final c = await store.save(jpeg);
    await store.delete(a);
    expect(await store.load(a), isNull);
    await store.keepOnly({b});
    expect(await store.load(b), jpeg);
    expect(await store.load(c), isNull);
    expect(await store.load('../../etc/passwd'), isNull);
    expect(() => store.write('../x', jpeg), throwsArgumentError);
    await store.deleteAll();
    expect(dir.listSync(), isEmpty);
  });
}
