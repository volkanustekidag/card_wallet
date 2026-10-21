import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:wallet_app/core/services/analytics_service.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const secureStorage =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final keychain = <String, String>{};
  var keychainLocked = true;
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('home_load_error_test');
    Hive.init(dir.path);
    Get.testMode = true;
    AnalyticsService.debugSink = (_, __) {};
    messenger.setMockMethodCallHandler(secureStorage, (call) async {
      if (keychainLocked) {
        throw PlatformException(code: '-25308', message: 'locked');
      }
      final args = call.arguments as Map;
      final key = args['key'] as String;
      switch (call.method) {
        case 'read':
          return keychain[key];
        case 'write':
          keychain[key] = args['value'] as String;
          return null;
      }
      return null;
    });
  });

  tearDown(() async {
    Get.reset();
    AnalyticsService.debugSink = null;
    messenger.setMockMethodCallHandler(secureStorage, null);
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('locked Keychain: error state instead of an empty wallet, then retry',
      () async {
    final controller = Get.put(HomeController());
    await controller.ensureLoaded();

    expect(controller.loadError.value, isTrue);
    expect(controller.walletItems, isEmpty);

    keychainLocked = false;
    await controller.retryLoad();

    expect(controller.loadError.value, isFalse);
  });
}
