import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/feature/scanner/add_flows.dart';

import '../../helpers/harness.dart';

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
            onPressed: () => pickManualEntry(context),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('the free plan shows what is left before anything is added',
      (tester) async {
    Get.put<PremiumController>(FakePremium());
    Get.put<HomeController>(FakeHome(
      loyalties: [loyalty('a', 'Bakery')],
      credits: [credit('c', bank: 'Chase')],
    ));
    await openSheet(tester);
    expect(find.text('cwFreeCount'.tr(args: ['1', '3'])), findsOneWidget);
    // One bank card already: that slot is used up.
    expect(find.text('cwFreeFull'.tr()), findsOneWidget);
    expect(find.text('cwFreeCount'.tr(args: ['0', '1'])), findsOneWidget);
  });

  testWidgets('Premium: no counters', (tester) async {
    Get.put<PremiumController>(FakePremium(premium: true));
    Get.put<HomeController>(FakeHome(loyalties: [loyalty('a', 'Bakery')]));
    await openSheet(tester);
    expect(
        find.textContaining('cwFreeCount'.tr(args: ['1', '3'])), findsNothing);
    expect(find.text('cwFreeFull'.tr()), findsNothing);
  });
}
