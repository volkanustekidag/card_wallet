import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/services/analytics_service.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';
import 'package:wallet_app/feature/search/wallet_search_page.dart';

/// Serves a fixed wallet instead of opening Hive boxes.
class _FakeHome extends HomeController {
  _FakeHome(List<WalletItem> items) {
    walletItems.assignAll(items);
  }

  @override
  // ignore: must_call_super
  void onInit() {}
}

void main() {
  final events = <String, Map<String, Object>?>{};

  setUp(() {
    events.clear();
    Get.testMode = true;
    AnalyticsService.debugSink = (name, params) => events[name] = params;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
    Get.put<HomeController>(_FakeHome([
      WalletItem.loyalty(LoyaltyCard(
        id: 'l1',
        name: 'Migros Money',
        brand: 'Migros',
        barcode: '1',
        barcodeFormat: 'EAN_13',
        colorId: 0,
      )),
      WalletItem.iban(IbanCard(
        id: 2,
        bankName: 'İş Bankası',
        cardHolder: 'Ali',
        iban: 'TR330006100519786457841326',
        swiftCode: '',
      )),
    ]));
  });

  tearDown(() {
    Get.reset();
    AnalyticsService.debugSink = null;
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: WalletSearchPage()));
    await tester.pump();
  }

  testWidgets('Turkish-insensitive query finds the card', (tester) async {
    await pumpPage(tester);
    await tester.enterText(
        find.byKey(const ValueKey('walletSearchField')), 'mıgros');
    await tester.pump();
    expect(find.text('Migros Money'), findsOneWidget);
    expect(find.text('İş Bankası'), findsNothing);

    await tester.enterText(
        find.byKey(const ValueKey('walletSearchField')), 'IS BANKASI');
    await tester.pump();
    expect(find.text('İş Bankası'), findsOneWidget);
  });

  testWidgets('leaving with a query logs counts only, never the text',
      (tester) async {
    await pumpPage(tester);
    await tester.enterText(
        find.byKey(const ValueKey('walletSearchField')), 'migros');
    await tester.pump();
    await tester.pumpWidget(const SizedBox());

    expect(events['search_used'], {
      'results_count': 1,
      'selected_type': 'none',
    });
    expect(events.toString(), isNot(contains('migros')));
  });

  testWidgets('no query, no event', (tester) async {
    await pumpPage(tester);
    await tester.pumpWidget(const SizedBox());
    expect(events.containsKey('search_used'), isFalse);
  });
}
