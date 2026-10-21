import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:wallet_app/core/controllers/auth_controller.dart';
import 'package:wallet_app/core/controllers/change_pin_controller.dart';
import 'package:wallet_app/core/data/local_services/auth_services/authentication_service.dart';

/// Records verifyPin calls instead of touching Hive / secure storage.
class _FakeAuthController extends AuthController {
  _FakeAuthController(this.result);
  final bool result;
  final calls = <String>[];

  // Skip AuthController.onInit: it reads the Hive auth box.
  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<bool> verifyPin(String pin) async {
    calls.add(pin);
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Get.reset);

  test('current PIN check goes through the rate-limited verifyPin', () async {
    final auth = Get.put<AuthController>(_FakeAuthController(true))
        as _FakeAuthController;
    final controller = ChangePinController(AuthenticationService());

    await controller.verifyCurrentPin('1234');

    expect(auth.calls, ['1234']);
    expect(controller.currentPinVerified.value, isTrue);
    expect(controller.verificationFailed.value, isFalse);
  });

  test('wrong PIN is reported as a failed verification', () async {
    Get.put<AuthController>(_FakeAuthController(false));
    final controller = ChangePinController(AuthenticationService());

    await controller.verifyCurrentPin('0000');

    expect(controller.currentPinVerified.value, isFalse);
    expect(controller.verificationFailed.value, isTrue);
  });

  test('formatLockRemaining picks minutes or seconds', () {
    // Without loaded translations easy_localization returns the key.
    expect(
      AuthController.formatLockRemaining(const Duration(seconds: 45)),
      contains('durationSecondsShort'),
    );
    expect(
      AuthController.formatLockRemaining(const Duration(seconds: 90)),
      contains('durationMinutesShort'),
    );
  });
}
