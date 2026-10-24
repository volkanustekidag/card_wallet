import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/brands/brand_catalog.dart';
import 'package:wallet_app/core/services/ui_prefs.dart';
import 'package:wallet_app/feature/scanner/brand_picker_sheet.dart';

import '../../helpers/harness.dart';

void main() {
  final h = Harness();
  setUpAll(() {
    final raw = File('assets/brands/brands.json').readAsStringSync();
    BrandCatalog.instance.debugSetEntries([
      for (final j in jsonDecode(raw) as List)
        BrandEntry.fromJson(j as Map<String, dynamic>),
    ]);
  });
  setUp(() async {
    await h.setUp();
    BrandCatalog.instance.debugZoneCountry = 'it';
    UiPrefs.instance.brandCountry.value = null;
  });
  tearDown(() async {
    BrandCatalog.instance.debugZoneCountry = null;
    UiPrefs.instance.brandCountry.value = null;
    await h.tearDown();
  });

  Future<void> openPicker(WidgetTester tester) async {
    await phoneSurface(tester);
    await pumpApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showBrandPicker(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  test('every market lists its own shops, not its neighbours\'', () {
    List<String> top(String country) {
      BrandCatalog.instance.debugZoneCountry = country;
      return BrandCatalog.instance
          .popular(limit: 40)
          .map((b) => b.name)
          .toList();
    }

    expect(top('se'), contains('ICA'));
    expect(top('se'), isNot(contains('Rema 1000')));
    expect(top('kr'), contains('E-Mart'));
    expect(top('kr'), isNot(contains('Aeon')));
    expect(top('jp'), isNot(contains('E-Mart')));
    expect(top('ar'), isNot(contains('Soriana')));
    expect(top('ae'), isNot(contains('DMart')));
    expect(top('za'), contains('Pick n Pay'));
  });

  testWidgets('shows where the list comes from and the local brands',
      (tester) async {
    await openPicker(tester);
    expect(
        find.text('cwBrandsFor'.tr(args: [countryName('it')])), findsOneWidget);
    expect(find.text('Esselunga'), findsOneWidget);
    expect(find.text('Target'), findsNothing);
  });

  testWidgets('picking another country re-ranks and is kept', (tester) async {
    await openPicker(tester);
    await tester.tap(find.byKey(const ValueKey('brandCountryChange')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('country_fr')));
    await tester.pumpAndSettle();
    await tapIo(tester, find.byKey(const ValueKey('country_fr')));

    expect(UiPrefs.instance.brandCountry.value, 'fr');
    expect(
        find.text('cwBrandsFor'.tr(args: [countryName('fr')])), findsOneWidget);
    expect(find.text('E.Leclerc'), findsOneWidget);
    expect(find.text('Esselunga'), findsNothing);

    UiPrefs.instance.brandCountry.value = null;
    await tester.runAsync(UiPrefs.instance.load);
    expect(UiPrefs.instance.brandCountry.value, 'fr');
  });

  testWidgets('automatic goes back to the phone\'s country', (tester) async {
    UiPrefs.instance.brandCountry.value = 'fr';
    await openPicker(tester);
    await tester.tap(find.byKey(const ValueKey('brandCountryChange')));
    await tester.pumpAndSettle();
    expect(find.text('cwCountryAutoSub'.tr(args: [countryName('it')])),
        findsOneWidget);
    await tapIo(tester, find.text('cwCountryAuto'.tr()));
    expect(UiPrefs.instance.brandCountry.value, isNull);
    expect(find.text('Esselunga'), findsOneWidget);
  });

  test('every catalogue country has a translated name', () {
    final en =
        jsonDecode(File('assets/docs/lang/en-US.json').readAsStringSync())
            as Map<String, dynamic>;
    final names = en['cwCountry'] as Map<String, dynamic>;
    for (final code in BrandCatalog.instance.countries) {
      expect(names.containsKey(code), isTrue, reason: code);
    }
  });
}
