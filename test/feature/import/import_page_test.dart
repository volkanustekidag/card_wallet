import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Trans;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:wallet_app/core/brands/brand_catalog.dart';
import 'package:wallet_app/core/data/storage/card_photo_store.dart';
import 'package:wallet_app/feature/import/importers.dart';
import 'package:wallet_app/feature/import/photo_import.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/data/local_services/card_services/loyalty_card/loyalty_card_service.dart';
import 'package:wallet_app/feature/import/import_page.dart';
import 'package:wallet_app/ui/components/cw_button.dart';

import '../../helpers/harness.dart';

/// Hands the page a fixed file instead of the system picker.
class _FakePicker extends FilePicker {
  PlatformFile? file;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async =>
      file == null ? null : FilePickerResult([file!]);
}

const _catima = '2\n\n'
    '_id,name\n\n'
    '_id,store,note,validfrom,expiry,balance,balancetype,cardid,barcodeid,barcodetype,headercolor,starstatus,lastused,archive\n'
    '1,Coffee Club,,,,0,,4006381333931,,EAN_13,-15132304,0,0,0\n'
    '2,Book Shop,,,,0,,9780306406157,,EAN_13,,0,0,0\n'
    '3,Broken,,,,0,,4006381333932,,EAN_13,,0,0,0\n';

void main() {
  final h = Harness();
  final picker = _FakePicker();
  late FakePremium premium;

  setUp(() async {
    await h.setUp();
    FilePicker.platform = picker;
    premium = FakePremium(loyaltyLimit: 50);
    Get.put<PremiumController>(premium);
    await LoyaltyCardService().openBox();
  });
  tearDown(h.tearDown);

  void serve(String name, List<int> bytes) => picker.file = PlatformFile(
      name: name, size: bytes.length, bytes: Uint8List.fromList(bytes));

  Future<void> openPage(WidgetTester tester) async {
    await phoneSurface(tester);
    await pumpApp(tester, const Scaffold(body: Text('HOME')));
    Get.to<void>(() => const ImportPage());
    await tester.pumpAndSettle();
  }

  Future<List<String>> storedNames(WidgetTester tester) async => [
        for (final c in (await tester
            .runAsync(LoyaltyCardService().getAllLoyaltyCards))!)
          c.name
      ];

  testWidgets('Catima file: valid cards preselected, invalid one off',
      (tester) async {
    serve('catima.csv', utf8.encode(_catima));
    await openPage(tester);
    await tester.tap(find.text('cwSrcCatima'.tr()));
    await tester.pumpAndSettle();
    expect(find.text('cwFoundInFile'.tr().toUpperCase()), findsOneWidget);
    expect(find.text('Coffee Club'), findsOneWidget);
    expect(find.text('cwImportInvalid'.tr()), findsOneWidget);
    expect(find.text('cwImportN'.plural(2)), findsOneWidget);
  });

  testWidgets('import saves the selected cards and closes', (tester) async {
    serve('catima.csv', utf8.encode(_catima));
    await openPage(tester);
    await tester.tap(find.text('cwSrcCatima'.tr()));
    await tester.pumpAndSettle();
    await tapIo(tester, find.widgetWithText(CwButton, 'cwImportN'.plural(2)));
    expect(find.text('HOME'), findsOneWidget);
    expect(await storedNames(tester),
        unorderedEquals(['Coffee Club', 'Book Shop']));
    expect(h.analytics['cards_imported'], isNotNull);
  });

  testWidgets('over the free limit: paywall, then only what fits',
      (tester) async {
    premium.loyaltyLimit = 1;
    serve('catima.csv', utf8.encode(_catima));
    await openPage(tester);
    await tester.tap(find.text('cwSrcCatima'.tr()));
    await tester.pumpAndSettle();
    await tapIo(tester, find.widgetWithText(CwButton, 'cwImportN'.plural(2)));
    expect(find.text('PAYWALL'), findsOneWidget);
    await tester.runAsync(() async => Get.back<void>());
    await settleIo(tester);
    expect(await storedNames(tester), ['Coffee Club']);
    expect(find.text('cwImportLimitPartial'.tr()), findsOneWidget);
  });

  testWidgets('password-protected export asks for the password',
      (tester) async {
    final a = Archive();
    final data = utf8.encode(_catima);
    a.addFile(ArchiveFile('catima.csv', data.length, data));
    serve('export.zip', ZipEncoder(password: 'secret').encode(a)!);
    await openPage(tester);
    await tester.tap(find.text('cwSrcCatima'.tr()));
    await tester.pumpAndSettle();
    expect(find.text('cwImportPassword'.tr()), findsOneWidget);
    await tester.enterText(fieldLabelled('cwPassword'.tr()), 'secret');
    await tester.tap(find.text('cwOpen'.tr()));
    await tester.pumpAndSettle();
    expect(find.text('Coffee Club'), findsOneWidget);
  });

  testWidgets('Stocard explains how to get the export first', (tester) async {
    serve('stocard.zip', utf8.encode(_catima));
    await openPage(tester);
    await tester.tap(find.text('cwSrcStocard'.tr()));
    await tester.pumpAndSettle();
    expect(find.text('cwStocardGuideTitle'.tr()), findsOneWidget);
    await tester.tap(find.text('cwChooseFile'.tr()));
    await tester.pumpAndSettle();
    expect(find.text('Coffee Club'), findsOneWidget);
  });

  testWidgets('unreadable file: an error, no list', (tester) async {
    serve('notes.txt', utf8.encode('just some text\nnothing else'));
    await openPage(tester);
    await tester.tap(find.text('cwSrcCsv'.tr()));
    await tester.pumpAndSettle();
    expect(find.text('cwFoundInFile'.tr().toUpperCase()), findsNothing);
    expect(find.text('cwFileUnreadable'.tr()), findsOneWidget);
  });

  group('photos & screenshots', () {
    final png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==');
    setUp(() async {
      CardPhotoStore.instance
        ..debugReset()
        ..debugDirectory = await Directory.systemTemp.createTemp('photos');
      PhotoImport.debugPick = () async => [XFile('a.png'), XFile('b.png')];
      PhotoImport.debugRead = (files) async => [
            const ImportedCard(
                name: 'Coffee Club',
                barcode: '4006381333931',
                format: 'EAN_13'),
            ImportedCard(
                name: 'Card 2', barcode: '', format: 'CODE_128', photo: png),
          ];
    });
    tearDown(() {
      PhotoImport.debugPick = null;
      PhotoImport.debugRead = null;
      CardPhotoStore.instance.debugReset();
    });

    testWidgets('lists every image; one without a barcode becomes a photo card',
        (tester) async {
      await openPage(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('importPhotos')));
      await tapIo(tester, find.byKey(const ValueKey('importPhotos')));
      expect(find.text('Coffee Club'), findsOneWidget);
      expect(find.text('Card 2'), findsOneWidget);
      expect(find.text('cwImportPhotoOnly'.tr()), findsOneWidget);
      // Both preselected: the photo stands in for the barcode.
      expect(find.text('cwImportN'.plural(2)), findsOneWidget);
    });

    testWidgets('names can be fixed before importing', (tester) async {
      await openPage(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('importPhotos')));
      await tapIo(tester, find.byKey(const ValueKey('importPhotos')));
      await tester.ensureVisible(find.text('Card 2'));
      await tester.tap(find.text('Card 2'));
      await tester.pumpAndSettle();
      await tester.enterText(fieldLabelled('cwName'.tr()), 'City Library');
      await tester.tap(find.text('cwSave'.tr()).last);
      await tester.pumpAndSettle();
      expect(find.text('City Library'), findsOneWidget);

      await tapIo(tester, find.widgetWithText(CwButton, 'cwImportN'.plural(2)));
      final cards =
          (await tester.runAsync(LoyaltyCardService().getAllLoyaltyCards))!;
      final library = cards.singleWhere((c) => c.name == 'City Library');
      expect(library.hasBarcode, isFalse);
      expect(library.frontPhoto, isNotNull);
      expect(
          await tester
              .runAsync(() => CardPhotoStore.instance.load(library.frontPhoto)),
          png);
      expect(
          cards.singleWhere((c) => c.name == 'Coffee Club').frontPhoto, isNull);
    });
  });

  group('reading a photo', () {
    setUp(() => BrandCatalog.instance.debugSetEntries([
          BrandEntry(
              name: 'Tesco',
              domain: 'tesco.com',
              color: 0xFF00539F,
              regions: const ['gb'],
              aliases: const ['clubcard']),
        ]));

    test('brand from the text, barcode kept, no photo needed', () {
      final c = PhotoImport.cardFromScan(
          raw: '634004012345',
          format: 'CODE_128',
          text: '9:41\nClubcard\nAlex Doe',
          photo: Uint8List(4),
          index: 1);
      expect(c.name, 'Tesco');
      expect(c.barcode, '634004012345');
      expect(c.photo, isNull);
      expect(c.color, 0xFF00539F);
    });

    test('no barcode: first readable line names it, the image is kept', () {
      final c = PhotoImport.cardFromScan(
          raw: null,
          format: null,
          text: '9:41\n12345678\nCity Library\nMember since 2020',
          photo: Uint8List(4),
          index: 3,
          fallbackName: (n) => 'Card $n');
      expect(c.name, 'City Library');
      expect(c.photoOnly, isTrue);
      expect(c.usable, isTrue);
    });

    test('nothing readable: Card N', () {
      final c = PhotoImport.cardFromScan(
          raw: null,
          format: null,
          text: '0042 1234',
          photo: Uint8List(4),
          index: 5,
          fallbackName: (n) => 'Card $n');
      expect(c.name, 'Card 5');
    });
  });
}
