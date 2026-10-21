import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/services/hive_backup_exclusion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    messenger.setMockMethodCallHandler(HiveBackupExclusion.channel,
        (call) async {
      calls.add(call);
      return true;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(HiveBackupExclusion.channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  Future<Directory> hiveDir() async => Directory('/app/Documents');

  test('iOS: flags the Hive directory', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await HiveBackupExclusion.apply(hiveDirectory: hiveDir);

    expect(calls, hasLength(1));
    expect(calls.single.method, 'excludeFromBackup');
    expect(calls.single.arguments, {'path': '/app/Documents'});
  });

  test('Android: no-op (allowBackup is false)', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await HiveBackupExclusion.apply(hiveDirectory: hiveDir);

    expect(calls, isEmpty);
  });

  test('native failure does not throw', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    messenger.setMockMethodCallHandler(HiveBackupExclusion.channel,
        (call) async => throw PlatformException(code: 'exclude_failed'));

    await HiveBackupExclusion.apply(hiveDirectory: hiveDir);
  });
}
