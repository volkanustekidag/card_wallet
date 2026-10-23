import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Trans;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/services/premium_service.dart';
import 'package:wallet_app/feature/premium/premium_page.dart';

import '../../helpers/harness.dart';

ProductDetails _product(String id, double price) => ProductDetails(
      id: id,
      title: id,
      description: '',
      price: '€${price.toStringAsFixed(2)}',
      rawPrice: price,
      currencyCode: 'EUR',
      currencySymbol: '€',
    );

void main() {
  final h = Harness();
  setUpAll(loadRealFonts);
  setUp(() async {
    await h.setUp();
    final premium = FakePremium();
    premium.availableProductsRx.assignAll([
      _product(PremiumService.weeklyProductId, 1.99),
      _product(PremiumService.monthlyProductId, 4.99),
      _product(PremiumService.yearlyProductId, 29.99),
    ]);
    Get.put<PremiumController>(premium);
  });
  tearDown(h.tearDown);

  for (final size in const [Size(375, 667), Size(393, 852)]) {
    for (final locale in const [Locale('en', 'US'), Locale('de', 'DE')]) {
      testWidgets(
          'buy button and plans on screen without scrolling: '
          '${size.width.toInt()}x${size.height.toInt()} ${locale.languageCode}',
          (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await pumpApp(tester, const PremiumPage(), locale: locale);
        await tester.pump(const Duration(milliseconds: 800));
        expect(tester.takeException(), isNull);

        final buy = find.byType(FilledButton);
        expect(buy, findsOneWidget);
        expect(tester.getRect(buy).bottom, lessThanOrEqualTo(size.height));
        expect(find.text('€29.99'), findsOneWidget);
        expect(tester.getRect(find.text('€29.99')).bottom,
            lessThan(tester.getRect(buy).top));
        expect(find.text('cwTerms'.tr()), findsOneWidget);
        expect(tester.getRect(find.text('cwTerms'.tr())).bottom,
            lessThanOrEqualTo(size.height));
        // The renewal terms of the selected plan sit under the button.
        expect(find.text('cwRenewsYear'.tr(args: ['€29.99'])), findsOneWidget);
      });
    }
  }

  testWidgets('renewal line follows the selected plan', (tester) async {
    await phoneSurface(tester);
    await pumpApp(tester, const PremiumPage());
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text('€4.99'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('cwRenewsMonth'.tr(args: ['€4.99'])), findsOneWidget);
    await tester.tap(find.text('€1.99'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('cwRenewsWeek'.tr(args: ['€1.99'])), findsOneWidget);
  });

  testWidgets('yearly shows its monthly price and the real saving',
      (tester) async {
    await phoneSurface(tester);
    await pumpApp(tester, const PremiumPage());
    await tester.pump(const Duration(milliseconds: 800));
    // 29.99 vs 12 x 4.99 = 59.88 -> 50 %.
    expect(find.text('cwSaveBadge'.tr(args: ['50'])), findsOneWidget);
    expect(find.textContaining('2.50'), findsOneWidget);
  });

  testWidgets('opened at the loyalty limit: says so instead of the tagline',
      (tester) async {
    await phoneSurface(tester);
    await pumpApp(tester, const SizedBox());
    Get.to<void>(() => const PremiumPage(),
        arguments: {'feature': 'unlimitedCards', 'card_type': 'loyalty'});
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(
        find.text('cwPayCtxLoyalty'
            .tr(args: ['${PremiumService.maxLoyaltyCardsForFree}'])),
        findsOneWidget);
    expect(find.text('cwPaySub'.tr()), findsNothing);
  });

  testWidgets('picking another plan moves nothing on screen', (tester) async {
    await phoneSurface(tester);
    await pumpApp(tester, const PremiumPage());
    await tester.pump(const Duration(milliseconds: 800));
    final button = find.byType(FilledButton).last;
    final before = tester.getRect(button);
    final plansBefore = tester.getRect(find.text('€1.99'));
    final headline = find.text('cwPayTitle2'.tr());
    final headlineBefore = tester.getRect(headline);
    for (final price in ['€4.99', '€1.99', '€29.99']) {
      await tester.tap(find.text(price));
      await tester.pump(const Duration(milliseconds: 800));
      expect(tester.getRect(button), before);
      expect(tester.getRect(find.text('€1.99')), plansBefore);
      expect(tester.getRect(headline), headlineBefore);
    }
  });
}
