import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/data/local_services/card_services/loyalty_card/loyalty_card_service.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/feature/loyalty_card/controller/loyalty_card_controller.dart';
import 'package:wallet_app/feature/loyalty_card/loyalty_card_detail_page.dart';

import '../../helpers/harness.dart';

void main() {
  final h = Harness();
  late LoyaltyCard card;
  late LoyaltyCardService service;

  setUp(() async {
    await h.setUp();
    service = LoyaltyCardService();
    await service.openBox();
    card = loyalty('gym', 'City Gym', notes: 'Locker 12');
    await service.addLoyaltyCard(card);
  });
  tearDown(h.tearDown);

  Future<void> open(WidgetTester tester, {bool readOnly = false}) async {
    await phoneSurface(tester);
    await pumpApp(tester, const Scaffold(body: SizedBox()));
    await pushIo(tester, LoyaltyCardDetailPage(card: card, readOnly: readOnly));
  }

  test('barcode text is grouped in fours', () {
    expect(formatBarcodeText('4006381333931'), '4006 3813 3393 1');
    expect(formatBarcodeText('1234'), '1234');
    expect(formatBarcodeText('AB CD'), 'AB CD');
  });

  testWidgets('shows name, grouped number, verified format and notes',
      (tester) async {
    await open(tester);
    expect(find.text('City Gym'), findsWidgets);
    expect(find.text('4006 3813 3393 1'), findsOneWidget);
    expect(find.textContaining('cwVerified'.tr()), findsOneWidget);
    expect(find.text('Locker 12'), findsOneWidget);
    expect(find.text('cwEdit'.tr()), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opening the barcode records a use (Up Next learns from it)',
      (tester) async {
    await open(tester);
    final stored = (await tester.runAsync(service.getAllLoyaltyCards))!
        .firstWhere((c) => c.id == 'gym');
    expect(stored.useCount, 1);
    expect(stored.usageLog, hasLength(1));
    expect(stored.lastUsedAt, isNotNull);
    expect(h.analytics.containsKey('barcode_shown'), isTrue);
  });

  testWidgets('read-only (from the widget while locked): barcode only',
      (tester) async {
    await open(tester, readOnly: true);
    expect(find.text('4006 3813 3393 1'), findsOneWidget);
    expect(find.text('openApp'.tr()), findsOneWidget);
    expect(find.text('cwEdit'.tr()), findsNothing);
    expect(find.text('cwCopy'.tr()), findsNothing);
    expect(find.text('Locker 12'), findsNothing);
    expect(find.bySemanticsLabel('cwMore'.tr()), findsNothing);
  });

  testWidgets('invalid barcode: no "verified" mark', (tester) async {
    card = loyalty('bad', 'Broken', barcode: '4006381333932');
    await tester.runAsync(() => service.addLoyaltyCard(card));
    await open(tester);
    expect(find.textContaining('cwVerified'.tr()), findsNothing);
  });

  testWidgets('tapping the barcode opens it full screen; tap closes',
      (tester) async {
    await open(tester);
    await tester.tap(find.text('4006 3813 3393 1'));
    await tester.pumpAndSettle();
    // The landscape route is on top: the dock can't be hit.
    expect(find.text('cwEdit'.tr()).hitTestable(), findsNothing);
    await tester.tapAt(const Offset(196, 426));
    await tester.pumpAndSettle();
    expect(find.text('cwEdit'.tr()).hitTestable(), findsOneWidget);
  });

  testWidgets('tap-opened full screen stays while the phone is upright',
      (tester) async {
    await open(tester);
    await tester.tap(find.text('4006 3813 3393 1'));
    await tester.pumpAndSettle();
    await tilt(tester, 0, 9.8);
    await tilt(tester, 0.3, 9.7);
    await tester.pumpAndSettle();
    expect(find.text('cwEdit'.tr()).hitTestable(), findsNothing);

    // Turned sideways and back upright: that closes it.
    await tilt(tester, 9.8, 0.2);
    await tilt(tester, 0, 9.8);
    await tester.pumpAndSettle();
    expect(find.text('cwEdit'.tr()).hitTestable(), findsOneWidget);
  });

  testWidgets('delete from the menu removes the card and closes',
      (tester) async {
    Get.put(LoyaltyCardController());
    await open(tester);
    await tester.tap(find.bySemanticsLabel('cwMore'.tr()));
    await tester.pumpAndSettle();
    await tapIo(tester, find.text('cwDelete'.tr()));
    expect(find.text('deleteCard'.tr()), findsOneWidget);
    await tapIo(tester, find.text('yes'.tr()).last);
    expect(find.byType(LoyaltyCardDetailPage), findsNothing);
    final left = (await tester.runAsync(service.getAllLoyaltyCards))!;
    expect(left.where((c) => c.id == 'gym'), isEmpty);
  });
}
