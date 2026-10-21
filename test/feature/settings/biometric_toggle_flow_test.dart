import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:wallet_app/core/controllers/auth_controller.dart';
import 'package:wallet_app/core/services/premium_service.dart';
import 'package:wallet_app/feature/settings/biometric_toggle_flow.dart';

/// Records toggleBiometric calls instead of touching local_auth / storage.
class _FakeAuthController extends AuthController {
  _FakeAuthController({required bool hasPin}) {
    hasPassword.value = hasPin;
  }
  final toggles = <bool>[];

  // Skip AuthController.onInit: it reads the Hive auth box.
  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<void> toggleBiometric(bool enabled) async => toggles.add(enabled);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Get.reset);

  test('a free user with a PIN turns biometric on directly', () async {
    expect(PremiumService.isPremium, isFalse);
    final auth = _FakeAuthController(hasPin: true);
    var pinPrompts = 0;

    await handleBiometricToggle(auth, true, createPin: () async {
      pinPrompts++;
      return true;
    });

    expect(auth.toggles, [true]);
    expect(pinPrompts, 0);
  });

  test('a free user without a PIN creates one first, then enables', () async {
    final auth = _FakeAuthController(hasPin: false);
    var pinPrompts = 0;

    await handleBiometricToggle(auth, true, createPin: () async {
      pinPrompts++;
      return true;
    });

    expect(pinPrompts, 1);
    expect(auth.toggles, [true]);
  });

  test('backing out of PIN creation leaves biometric off', () async {
    final auth = _FakeAuthController(hasPin: false);

    await handleBiometricToggle(auth, true, createPin: () async => null);

    expect(auth.toggles, isEmpty);
  });

  test('turning biometric off needs no PIN prompt', () async {
    final auth = _FakeAuthController(hasPin: false);

    await handleBiometricToggle(auth, false,
        createPin: () async => fail('no PIN prompt when disabling'));

    expect(auth.toggles, [false]);
  });

  test('nothing in lib opens the paywall for biometric', () {
    final gate = RegExp(r'''(openPremiumGate|'feature':)\s*\(?\s*'biometric'\s*''');
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => gate.hasMatch(f.readAsStringSync()))
        .map((f) => f.path)
        .toList();
    expect(offenders, isEmpty);
  });
}
