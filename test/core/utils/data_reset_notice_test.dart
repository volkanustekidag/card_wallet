import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/data/storage/encrypted_box_opener.dart';
import 'package:wallet_app/core/utils/data_reset_notice.dart';

class _FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> values = {};
  bool failDelete = false;

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      values[key];

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (failDelete) throw PlatformException(code: 'keystore');
    values.remove(key);
  }
}

void main() {
  const key = EncryptedBoxOpener.dataResetNoticeKey;

  test('no flag: nothing to show', () async {
    final storage = _FakeSecureStorage();
    expect(await DataResetNotice(storage: storage).consumePending(), isFalse);
  });

  test('flag set: shown once, then cleared', () async {
    final storage = _FakeSecureStorage()..values[key] = 'true';
    final notice = DataResetNotice(storage: storage);

    expect(await notice.consumePending(), isTrue);
    expect(storage.values.containsKey(key), isFalse);
    expect(await notice.consumePending(), isFalse);
  });

  test('flag cannot be cleared: skipped, kept for a later launch', () async {
    final storage = _FakeSecureStorage()
      ..values[key] = 'true'
      ..failDelete = true;

    expect(await DataResetNotice(storage: storage).consumePending(), isFalse);
    expect(storage.values[key], 'true');
  });
}
