import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/data/local_services/card_services/loyalty_card/loyalty_card_service.dart';
import 'package:wallet_app/core/data/storage/card_photo_store.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/utils/session_prompt_gate.dart';
import 'package:wallet_app/feature/add_loyalty_card/add_loyalty_card_page.dart';
import 'package:wallet_app/feature/add_loyalty_card/controller/add_loyalty_card_controller.dart';
import 'package:wallet_app/feature/loyalty_card/controller/loyalty_card_controller.dart';
import 'package:wallet_app/feature/loyalty_card/loyalty_card_detail_page.dart';
import 'package:wallet_app/feature/loyalty_card/widgets/card_photos.dart';
import 'package:wallet_app/ui/components/cw_button.dart';

import '../../helpers/harness.dart';

/// 1x1 PNG.
final _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==');

void main() {
  final h = Harness();
  final store = CardPhotoStore.instance;
  late LoyaltyCardService service;
  late String front;
  late String back;

  setUp(() async {
    await h.setUp();
    SessionPromptGate.markUsed();
    store.debugReset();
    store.debugDirectory = await Directory.systemTemp.createTemp('photos');
    front = await store.save(_png);
    back = await store.save(_png);
    service = LoyaltyCardService();
    await service.openBox();
  });
  tearDown(() async {
    store.debugReset();
    await h.tearDown();
  });

  Future<void> openDetail(WidgetTester tester, LoyaltyCard card) async {
    await tester.runAsync(() => service.addLoyaltyCard(card));
    await phoneSurface(tester);
    await pumpApp(tester, const Scaffold(body: SizedBox()));
    await pushIo(tester, LoyaltyCardDetailPage(card: card));
  }

  testWidgets('a card without a barcode shows its photo instead',
      (tester) async {
    await openDetail(
        tester,
        loyalty('lib', 'City Library',
            barcode: '', frontPhoto: front, backPhoto: back));
    expect(find.byKey(const ValueKey('detailPhotoPanel')), findsOneWidget);
    expect(find.text('cwShowPhotoAtCheckout'.tr()), findsOneWidget);
    // Nothing to copy and nothing a Wallet pass could show.
    expect(find.text('cwCopy'.tr()), findsNothing);
    expect(find.text('cwDockWallet'.tr()), findsNothing);
    expect(find.text('cwShare'.tr()), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('detailPhotoPanel')));
    await tester.pumpAndSettle();
    expect(find.byType(CardPhotoViewer), findsOneWidget);
    expect(find.text('cwPhotoFront'.tr()), findsOneWidget);
    expect(find.text('cwPhotoBack'.tr()), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('cwClose'.tr()).last);
    await tester.pumpAndSettle();
    expect(find.byType(CardPhotoViewer), findsNothing);
  });

  testWidgets('a barcode card keeps the barcode, photos sit underneath',
      (tester) async {
    await openDetail(
        tester, loyalty('gym', 'City Gym', frontPhoto: front, backPhoto: back));
    expect(find.text('4006 3813 3393 1'), findsOneWidget);
    expect(find.byKey(const ValueKey('detailPhotoPanel')), findsNothing);
    expect(find.byKey(const ValueKey('detailPhoto_0')), findsOneWidget);
    expect(find.byKey(const ValueKey('detailPhoto_1')), findsOneWidget);
    expect(find.text('cwCopy'.tr()), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('detailPhoto_1')));
    await tester.tap(find.byKey(const ValueKey('detailPhoto_1')));
    await tester.pumpAndSettle();
    expect(find.byType(CardPhotoViewer), findsOneWidget);
  });

  testWidgets('deleting a card deletes its photos', (tester) async {
    final card = loyalty('x', 'Old', frontPhoto: front);
    await tester.runAsync(() async {
      await service.addLoyaltyCard(card);
      await service.removeLoyaltyCard(card);
    });
    expect(await tester.runAsync(() => store.load(front)), isNull);
    expect(await tester.runAsync(() => store.load(back)), isNotNull);
  });

  group('form', () {
    setUp(() {
      Get.put<PremiumController>(FakePremium());
      Get.put(AddLoyaltyCardController());
      Get.put(LoyaltyCardController());
    });

    CwButton submit(WidgetTester tester) =>
        tester.widget<CwButton>(find.byType(CwButton).last);

    testWidgets('a front photo makes the barcode optional', (tester) async {
      await phoneSurface(tester);
      await pumpApp(tester, const Scaffold(body: Text('HOME')));
      Get.to<void>(() => const AddLoyaltyCardPage(brandFirst: false));
      await tester.pumpAndSettle();
      final c = Get.find<AddLoyaltyCardController>();

      expect(find.byKey(const ValueKey('photoSlotFront')), findsOneWidget);
      expect(find.byKey(const ValueKey('photoSlotBack')), findsOneWidget);
      await tester.enterText(fieldLabelled('cwName'.tr()), 'City Library');
      await tester.pump();
      expect(submit(tester).onPressed, isNull);

      c.setPhoto(front: true, id: front); // as if picked
      await tester.pump();
      expect(submit(tester).onPressed, isNotNull);
      expect(find.text('cwPhotoInsteadOfBarcode'.tr()), findsOneWidget);

      final remove = find.byKey(ValueKey('photoRemove_${'cwPhotoFront'.tr()}'));
      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.pump();
      expect(c.currentCard.value.frontPhoto, isNull);
      expect(submit(tester).onPressed, isNull);
    });

    testWidgets('saves a photo-only card', (tester) async {
      await phoneSurface(tester);
      await pumpApp(tester, const Scaffold(body: Text('HOME')));
      Get.to<void>(() => const AddLoyaltyCardPage(brandFirst: false));
      await tester.pumpAndSettle();
      final c = Get.find<AddLoyaltyCardController>();
      await tester.enterText(fieldLabelled('cwName'.tr()), 'City Library');
      c.setPhoto(front: true, id: front);
      await tester.pump();
      await tapIo(tester, find.byType(CwButton).last);

      final saved = (await tester.runAsync(service.getAllLoyaltyCards))!
          .singleWhere((x) => x.name == 'City Library');
      expect(saved.hasBarcode, isFalse);
      expect(saved.frontPhoto, front);
    });
  });
}
