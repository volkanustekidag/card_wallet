import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/controllers/auth_controller.dart';
import 'package:wallet_app/feature/auth/pin_action_page.dart';
import 'package:wallet_app/feature/auth/widgets/forgot_pin_sheet.dart';

import '../../helpers/harness.dart';

/// The phone's lock answers [owner]; recoveries are recorded.
class _FakeAuth extends AuthController {
  _FakeAuth({required this.owner, bool deviceLock = true}) {
    hasPassword.value = true;
    isDeviceLockAvailable.value = deviceLock;
  }

  final bool owner;
  int checks = 0;
  final recoveries = <bool>[];

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<bool> verifyDeviceOwner() async {
    checks++;
    return owner;
  }

  @override
  Future<void> completeRecovery({required bool newPin}) async =>
      recoveries.add(newPin);
}

void main() {
  final h = Harness();
  setUp(h.setUp);
  tearDown(h.tearDown);

  Future<void> openSheet(WidgetTester tester) async {
    await phoneSurface(tester);
    await pumpApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showForgotPinSheet(context),
            child: const Text('forgot'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('forgot'));
    await tester.pumpAndSettle();
  }

  test('offered with a screen lock even without biometrics', () {
    final auth = _FakeAuth(owner: true);
    expect(auth.isBiometricAvailable.value, isFalse);
    expect(auth.isPinRecoveryAvailable, isTrue);
    expect(_FakeAuth(owner: true, deviceLock: false).isPinRecoveryAvailable,
        isFalse);
  });

  testWidgets('screen lock passed: straight to setting a new PIN',
      (tester) async {
    final auth = Get.put<AuthController>(_FakeAuth(owner: true)) as _FakeAuth;
    await openSheet(tester);
    expect(find.text('cwForgotBody'.tr()), findsOneWidget);
    await tester.tap(find.text('cwForgotUseLock'.tr()));
    await tester.pumpAndSettle();
    expect(auth.checks, 1);
    expect(find.byType(PinActionPage), findsOneWidget);

    // Backing out of the new PIN still unlocks; home will nudge.
    Get.back<bool>();
    await tester.pumpAndSettle();
    expect(auth.recoveries, [false]);
  });

  testWidgets('screen lock failed: nothing unlocks', (tester) async {
    final auth = Get.put<AuthController>(_FakeAuth(owner: false)) as _FakeAuth;
    await openSheet(tester);
    await tester.tap(find.text('cwForgotUseLock'.tr()));
    await tester.pumpAndSettle();
    expect(auth.checks, 1);
    expect(find.byType(PinActionPage), findsNothing);
    expect(auth.recoveries, isEmpty);
  });

  testWidgets('cancel: no check at all', (tester) async {
    final auth = Get.put<AuthController>(_FakeAuth(owner: true)) as _FakeAuth;
    await openSheet(tester);
    await tester.tap(find.text('cancel'.tr()));
    await tester.pumpAndSettle();
    expect(auth.checks, 0);
    expect(auth.recoveries, isEmpty);
  });
}
