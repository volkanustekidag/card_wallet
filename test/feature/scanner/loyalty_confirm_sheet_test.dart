import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/brands/brand_catalog.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/data/local_services/card_services/loyalty_card/loyalty_card_service.dart';
import 'package:wallet_app/core/utils/session_prompt_gate.dart';
import 'package:wallet_app/feature/add_loyalty_card/controller/add_loyalty_card_controller.dart';
import 'package:wallet_app/feature/loyalty_card/controller/loyalty_card_controller.dart';
import 'package:wallet_app/feature/scanner/loyalty_confirm_sheet.dart';
import 'package:wallet_app/ui/components/cw_button.dart';

import '../../helpers/harness.dart';

void main() {
  final h = Harness();
  final starbucks = BrandEntry(
    name: 'Starbucks',
    domain: 'starbucks.com',
    color: 0xFF00704A,
    regions: const ['global'],
  );

  setUp(() async {
    await h.setUp();
    SessionPromptGate.markUsed();
    Get.put<PremiumController>(FakePremium());
    Get.put(AddLoyaltyCardController());
    Get.put(LoyaltyCardController());
    await LoyaltyCardService().openBox();
  });
  tearDown(h.tearDown);

  bool? result;

  Future<void> openSheet(WidgetTester tester,
      {required String raw, required String format, BrandEntry? brand}) async {
    result = null;
    await phoneSurface(tester);
    await pumpApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showLoyaltyConfirmSheet(context,
                  raw: raw, format: format, brand: brand);
            },
            child: const Text('scan'),
          ),
        ),
      ),
    );
    await tapIo(tester, find.text('scan'));
  }

  CwButton addButton(WidgetTester tester) => tester
      .widget<CwButton>(find.widgetWithText(CwButton, 'cwAddToWallet'.tr()));

  testWidgets('brand read from the card: name filled, saved with its colour',
      (tester) async {
    await openSheet(tester,
        raw: '4006381333931', format: 'EAN_13', brand: starbucks);
    expect(find.text('cwLooksGood'.tr()), findsOneWidget);
    expect(find.textContaining('cwVerified'.tr()), findsOneWidget);
    expect(find.text('Starbucks · ${'cwMatchedCatalog'.tr()}'), findsOneWidget);

    await tapIo(tester, find.text('cwAddToWallet'.tr()));
    expect(result, isTrue);
    expect(find.text('cwLooksGood'.tr()), findsNothing);
    final saved =
        (await tester.runAsync(LoyaltyCardService().getAllLoyaltyCards))!;
    expect(saved.single.name, 'Starbucks');
    expect(saved.single.brand, 'Starbucks');
    expect(saved.single.barcodeFormat, 'EAN_13');
    expect(saved.single.website, 'starbucks.com');
    expect(saved.single.brandColor, 0xFF00704A);
  });

  testWidgets('no brand: needs a name before it can be added', (tester) async {
    await openSheet(tester, raw: 'MEMBER-778', format: 'CODE_128');
    expect(addButton(tester).onPressed, isNull);
    await tester.enterText(fieldLabelled('cwName'.tr()), 'Climbing gym');
    await tester.pump();
    expect(addButton(tester).onPressed, isNotNull);
  });

  testWidgets('a barcode that fails its check is flagged', (tester) async {
    await openSheet(tester, raw: '4006381333932', format: 'EAN_13');
    expect(find.text('cwFormatInvalid'.tr()), findsOneWidget);
    expect(find.textContaining('cwVerified'.tr()), findsNothing);
  });

  testWidgets('dismissed: nothing saved', (tester) async {
    await openSheet(tester,
        raw: '4006381333931', format: 'EAN_13', brand: starbucks);
    await tester.tapAt(const Offset(200, 30));
    await settleIo(tester);
    expect(result, isFalse);
    final saved =
        (await tester.runAsync(LoyaltyCardService().getAllLoyaltyCards))!;
    expect(saved, isEmpty);
  });
}
