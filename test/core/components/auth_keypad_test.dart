import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/components/auth_component.dart';
import 'package:wallet_app/core/controllers/auth_controller.dart';
import 'package:wallet_app/core/data/local_services/auth_services/authentication_service.dart';

import '../../helpers/harness.dart';

void main() {
  final h = Harness();
  late AuthController auth;

  setUp(() async {
    await h.setUp();
    await AuthenticationService().openBox();
    auth = Get.put(AuthController());
  });
  tearDown(h.tearDown);

  Future<TextEditingController> pumpKeypad(
    WidgetTester tester, {
    void Function(String)? onCompleted,
    VoidCallback? onBiometric,
    VoidCallback? onForgot,
    bool lockScreen = false,
  }) async {
    final ctrl = TextEditingController();
    addTearDown(ctrl.dispose);
    await phoneSurface(tester);
    await pumpApp(
      tester,
      Scaffold(
        body: AuthViews(
          text: 'enterPin',
          textEditingController: ctrl,
          onCompleted: onCompleted,
          onBiometric: onBiometric,
          onForgot: onForgot,
          lockScreen: lockScreen,
        ),
      ),
    );
    return ctrl;
  }

  Future<void> type(WidgetTester tester, String digits) async {
    for (final d in digits.split('')) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
  }

  testWidgets('four digits complete the PIN; a fifth is ignored',
      (tester) async {
    String? done;
    final ctrl = await pumpKeypad(tester, onCompleted: (p) => done = p);
    await type(tester, '1234');
    expect(done, '1234');
    await type(tester, '5');
    expect(ctrl.text, '1234');
  });

  testWidgets('delete removes the last digit', (tester) async {
    final ctrl = await pumpKeypad(tester, onCompleted: (_) {});
    await type(tester, '12');
    await tester.tap(find.bySemanticsLabel(
        const DefaultMaterialLocalizations().deleteButtonTooltip));
    await tester.pump();
    expect(ctrl.text, '1');
  });

  testWidgets('"Forgot?" only before typing; biometric key when offered',
      (tester) async {
    var forgot = 0, bio = 0;
    await pumpKeypad(tester,
        onCompleted: (_) {},
        onForgot: () => forgot++,
        onBiometric: () => bio++);
    expect(find.text('cwForgot'.tr()), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('biometricAuthReason'.tr()));
    expect(bio, 1);
    await type(tester, '7');
    expect(find.text('cwForgot'.tr()), findsNothing);
  });

  testWidgets('a wrong PIN clears the dots', (tester) async {
    final ctrl = await pumpKeypad(tester, onCompleted: (_) {});
    await type(tester, '123');
    auth.authenticationFailed.value = true;
    await tester.pump();
    expect(ctrl.text, isEmpty);
    expect(find.text('cwWrongPin'.tr()), findsOneWidget);
    // Still there after the red flash ends, gone once typing resumes.
    auth.authenticationFailed.value = false;
    await tester.pumpAndSettle();
    expect(find.text('cwWrongPin'.tr()), findsOneWidget);
    await type(tester, '1');
    expect(find.text('cwWrongPin'.tr()), findsNothing);
  });

  testWidgets('lock screen headline', (tester) async {
    await pumpKeypad(tester, onCompleted: (_) {}, lockScreen: true);
    expect(find.text('cwLocked'.tr()), findsOneWidget);
  });
}
