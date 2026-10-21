import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wallet_app/core/data/storage/encrypted_box_opener.dart';

class _FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> values = {};
  int failReads = 0;
  int failWrites = 0;
  int reads = 0;

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    reads++;
    if (failReads > 0) {
      failReads--;
      throw PlatformException(code: '-25308', message: 'interaction not allowed');
    }
    return values[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (failWrites > 0) {
      failWrites--;
      throw PlatformException(code: 'keystore', message: 'write failed');
    }
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}

const _box = 'cards';
const _key = 'cards_key';

void main() {
  late Directory dir;
  late _FakeSecureStorage storage;
  late List<String?> reported;

  EncryptedBoxOpener opener() => EncryptedBoxOpener(
        storage: storage,
        retryDelay: Duration.zero,
        report: (e, st, {reason}) => reported.add(reason),
      );

  Future<void> seedBox() async {
    final box = await opener().open<String>(boxName: _box, keyName: _key);
    await box.put('a', 'stored value');
    await box.close();
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('encrypted_box_opener_test');
    Hive.init(dir.path);
    storage = _FakeSecureStorage();
    reported = [];
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('no box yet: creates a key and an empty box (first install)', () async {
    expect(await Hive.boxExists(_box), isFalse);

    final box = await opener().open<String>(boxName: _box, keyName: _key);

    expect(box.isEmpty, isTrue);
    expect(storage.values[_key], isNotNull);
    expect(storage.values[EncryptedBoxOpener.dataResetNoticeKey], isNull);
    expect(reported, isEmpty);
  });

  test('box and key present: existing data is read', () async {
    await seedBox();

    final box = await opener().open<String>(boxName: _box, keyName: _key);

    expect(box.get('a'), 'stored value');
    expect(storage.values[EncryptedBoxOpener.dataResetNoticeKey], isNull);
    expect(reported, isEmpty);
  });

  test('box without key: replaced by an empty box, notice flag set', () async {
    await seedBox();
    final oldKey = storage.values.remove(_key);

    final box = await opener().open<String>(boxName: _box, keyName: _key);

    expect(box.isEmpty, isTrue);
    expect(storage.values[_key], isNotNull);
    expect(storage.values[_key], isNot(oldKey));
    expect(storage.values[EncryptedBoxOpener.dataResetNoticeKey], 'true');
    expect(reported, ['orphan_box_$_box']);

    // The new box is usable and survives a reopen with the new key.
    await box.put('b', 'new value');
    await box.close();
    final reopened = await opener().open<String>(boxName: _box, keyName: _key);
    expect(reopened.get('b'), 'new value');
  });

  test('secure storage error: data kept, StorageUnavailableException', () async {
    await seedBox();
    storage.failReads = 2;
    storage.reads = 0;

    await expectLater(
      opener().open<String>(boxName: _box, keyName: _key),
      throwsA(isA<StorageUnavailableException>()),
    );

    expect(storage.reads, 2, reason: 'one retry');
    expect(await Hive.boxExists(_box), isTrue);
    expect(storage.values[EncryptedBoxOpener.dataResetNoticeKey], isNull);
    expect(reported, isEmpty);

    // Once the Keychain is reachable again the original data is there.
    final box = await opener().open<String>(boxName: _box, keyName: _key);
    expect(box.get('a'), 'stored value');
  });

  test('transient secure storage error recovers on the retry', () async {
    await seedBox();
    storage.failReads = 1;

    final box = await opener().open<String>(boxName: _box, keyName: _key);

    expect(box.get('a'), 'stored value');
  });

  test('orphan box with failing key write: file is not deleted', () async {
    await seedBox();
    storage.values.remove(_key);
    storage.failWrites = 2;

    await expectLater(
      opener().open<String>(boxName: _box, keyName: _key),
      throwsA(isA<StorageUnavailableException>()),
    );
    expect(await Hive.boxExists(_box), isTrue);
  });

  test('first install with failing key write: no box is created', () async {
    storage.failWrites = 2;

    await expectLater(
      opener().open<String>(boxName: _box, keyName: _key),
      throwsA(isA<StorageUnavailableException>()),
    );
    expect(await Hive.boxExists(_box), isFalse);
  });
}
