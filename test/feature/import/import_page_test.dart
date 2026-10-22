import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Trans;
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
}
