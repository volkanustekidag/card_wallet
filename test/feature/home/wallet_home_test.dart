import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/services/ui_prefs.dart';
import 'package:wallet_app/core/utils/card_reminder_rules.dart';
import 'package:wallet_app/core/utils/tag_index.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/feature/home/wallet_home.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';
import 'package:wallet_app/feature/home/widgets/home_order.dart';
import 'package:wallet_app/ui/card/wallet_card_faces.dart';

import '../../helpers/harness.dart';

void main() {
  final h = Harness();
  setUpAll(loadRealFonts);
  setUp(() async {
    await h.setUp();
    UiPrefs.instance.upNext.value = true;
    UiPrefs.instance.homeGrid.value = false;
    UiPrefs.instance.homeSort.value = 'smart';
    UiPrefs.instance.manualOrder.clear();
  });
  tearDown(h.tearDown);

  /// Uses at [hour] on each of the last [days] days.
  List<int> habit(int hour, {int days = 6}) {
    final now = DateTime.now();
    return [
      for (var d = days; d >= 1; d--)
        DateTime(now.year, now.month, now.day - d, hour, now.minute)
            .millisecondsSinceEpoch,
    ];
  }

  group('stackOrder', () {
    final items = mergeAndSort(
      credits: [
        credit('c1'),
        credit('c2', tags: [kFavoriteTag])
      ],
      ibans: [
        iban(1),
        iban(2, tags: [kFavoriteTag])
      ],
      loyalties: [loyalty('l1', 'Cafe'), loyalty('l2', 'Market')],
    );

    test('loyalty, then IBAN, then bank cards; favourites lead each kind', () {
      final order = stackOrder(items, HomeFilter.all);
      expect(order.map((i) => i.kind), [
        WalletItemKind.loyalty,
        WalletItemKind.loyalty,
        WalletItemKind.iban,
        WalletItemKind.iban,
        WalletItemKind.credit,
        WalletItemKind.credit,
      ]);
      expect(order[2].isFavorite, isTrue);
      expect(order[4].isFavorite, isTrue);
    });

    test('a filter keeps only its kind', () {
      final order = stackOrder(items, HomeFilter.credit);
      expect(order, hasLength(2));
      expect(order.every((i) => i.kind == WalletItemKind.credit), isTrue);
    });

    test('the habit card leads the loyalty group', () {
      final order = stackOrder(
        mergeAndSort(credits: [], ibans: [], loyalties: [
          loyalty('a', 'Never used'),
          loyalty('b', 'Every day now',
              useCount: 6, usageLog: habit(DateTime.now().hour)),
        ]),
        HomeFilter.all,
      );
      expect((order.first.card as dynamic).id, 'b');
    });
  });

  Future<FakeHome> pumpHome(WidgetTester tester, FakeHome home) async {
    await phoneSurface(tester);
    Get.put<HomeController>(home);
    await pumpApp(tester, Scaffold(body: WalletHome(controller: home)));
    return home;
  }

  testWidgets('empty wallet: quick start instead of a stack', (tester) async {
    await pumpHome(tester, FakeHome());
    expect(find.text('cwEmptyTitle'.tr()), findsOneWidget);
    expect(find.text('cwQsLoyalty'.tr()), findsOneWidget);
    expect(find.text('cwQsImport'.tr()), findsOneWidget);
    expect(find.byKey(const ValueKey('homeUpNext')), findsNothing);
  });

  testWidgets('quick start leads with what the user said they carry',
      (tester) async {
    UiPrefs.instance.carry.assignAll(['iban', 'cards']);
    addTearDown(UiPrefs.instance.carry.clear);
    await pumpHome(tester, FakeHome());
    double y(String key) => tester.getTopLeft(find.text(key.tr())).dy;
    expect(y('cwQsCard'), lessThan(y('cwQsLoyalty')));
    expect(y('cwQsIban'), lessThan(y('cwQsLoyalty')));
    expect(y('cwQsLoyalty'), lessThan(y('cwQsImport')));
  });

  testWidgets('Up Next shows the card used at this hour', (tester) async {
    await pumpHome(
      tester,
      FakeHome(loyalties: [
        loyalty('a', 'Bakery'),
        loyalty('b', 'Gym', useCount: 6, usageLog: habit(DateTime.now().hour)),
      ]),
    );
    final banner = find.byKey(const ValueKey('homeUpNext'));
    expect(banner, findsOneWidget);
    expect(find.descendant(of: banner, matching: find.text('Gym')),
        findsOneWidget);
    expect(
        find.descendant(of: banner, matching: find.text('cwUpNextHabit'.tr())),
        findsOneWidget);
  });

  testWidgets('Up Next off in settings: no banner', (tester) async {
    UiPrefs.instance.upNext.value = false;
    await pumpHome(tester, FakeHome(loyalties: [loyalty('a', 'Bakery')]));
    expect(find.byKey(const ValueKey('homeUpNext')), findsNothing);
  });

  testWidgets('segments filter the stack; Up Next only for loyalty',
      (tester) async {
    await pumpHome(
      tester,
      FakeHome(
        loyalties: [loyalty('a', 'Bakery')],
        credits: [credit('c', bank: 'Chase')],
        ibans: [iban(1, bank: 'Deutsche Bank')],
      ),
    );
    expect(find.byKey(const ValueKey('homeUpNext')), findsOneWidget);

    await tester.tap(find.text('cwSegCards'.tr()));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('homeUpNext')), findsNothing);
    expect(find.text('Bakery'), findsNothing);
    expect(find.text('Deutsche Bank'), findsNothing);

    await tester.tap(find.text('cwSegBank'.tr()));
    await tester.pumpAndSettle();
    expect(find.text('Deutsche Bank'), findsWidgets);
    expect(find.text('Chase'), findsNothing);
  });

  testWidgets('empty segment offers to add that kind', (tester) async {
    await pumpHome(tester, FakeHome(loyalties: [loyalty('a', 'Bakery')]));
    await tester.tap(find.text('cwSegBank'.tr()));
    await tester.pumpAndSettle();
    expect(find.text('cwSegEmpty'.tr()), findsOneWidget);
    expect(find.text('cwAddCard'.tr()), findsWidgets);
  });

  testWidgets('a payment due soon shows on the count line and as a badge',
      (tester) async {
    final card = credit('c', bank: 'Chase', dueDay: 1, paymentReminder: true);
    final home = FakeHome(credits: [card, credit('d', bank: 'Amex')]);
    home.upcomingPaymentNotices.assignAll([
      UpcomingCardDate(
        card: card,
        targetDate: DateTime.now().add(const Duration(days: 2)),
        daysUntil: 2,
      ),
    ]);
    await pumpHome(tester, home);
    expect(
        find.text('cwNoticePayment'.tr(namedArgs: {
          'card': 'Chase',
          'when': 'cwWhenInDays'.plural(2),
        })),
        findsOneWidget);
    expect(find.text('cwDueBadge'.tr(args: ['2'])), findsOneWidget);
  });

  testWidgets('no overflow with a long wallet in dark mode', (tester) async {
    await phoneSurface(tester);
    final home = FakeHome(
      loyalties: [
        for (var i = 0; i < 8; i++)
          loyalty('l$i', 'A very long loyalty programme name number $i'),
      ],
      credits: [credit('c', bank: 'A bank with an unusually long name')],
      ibans: [iban(1)],
    );
    Get.put<HomeController>(home);
    await pumpApp(tester, Scaffold(body: WalletHome(controller: home)),
        mode: ThemeMode.dark);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  group('grid view', () {
    FakeHome wallet() => FakeHome(
          loyalties: [loyalty('a', 'Bakery'), loyalty('b', 'Gym')],
          credits: [credit('c', bank: 'Chase')],
          ibans: [iban(1, bank: 'Deutsche Bank')],
        );

    testWidgets('the switch turns the stack into a grid and is kept',
        (tester) async {
      await pumpHome(tester, wallet());
      expect(find.byType(WalletMiniCard), findsNothing);

      await tapIo(tester, find.bySemanticsLabel('cwViewGrid'.tr()));
      expect(find.byType(WalletMiniCard), findsNWidgets(4));
      expect(UiPrefs.instance.homeGrid.value, isTrue);

      UiPrefs.instance.homeGrid.value = false;
      await tester.runAsync(UiPrefs.instance.load);
      expect(UiPrefs.instance.homeGrid.value, isTrue);
      await tester.pumpAndSettle();
      expect(find.byType(WalletMiniCard), findsNWidgets(4));

      await tapIo(tester, find.bySemanticsLabel('cwViewStack'.tr()));
      expect(find.byType(WalletMiniCard), findsNothing);
    });

    testWidgets('segments filter the grid too', (tester) async {
      UiPrefs.instance.homeGrid.value = true;
      await pumpHome(tester, wallet());
      await tester.tap(find.text('cwSegLoyalty'.tr()));
      await tester.pumpAndSettle();
      expect(find.byType(WalletMiniCard), findsNWidgets(2));
    });

    testWidgets('a payment due soon shows as a badge on the tile',
        (tester) async {
      UiPrefs.instance.homeGrid.value = true;
      final card = credit('c', bank: 'Chase', dueDay: 1, paymentReminder: true);
      final home = FakeHome(credits: [card]);
      home.upcomingPaymentNotices.assignAll([
        UpcomingCardDate(
          card: card,
          targetDate: DateTime.now().add(const Duration(days: 2)),
          daysUntil: 2,
        ),
      ]);
      await pumpHome(tester, home);
      expect(
          find.descendant(
              of: find.byType(WalletMiniCard),
              matching: find.text('cwDueBadge'.tr(args: ['2']))),
          findsOneWidget);
    });

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('no overflow with long names ($mode, de)', (tester) async {
        UiPrefs.instance.homeGrid.value = true;
        await phoneSurface(tester);
        final home = FakeHome(
          loyalties: [
            for (var i = 0; i < 9; i++)
              loyalty('l$i', 'A very long loyalty programme name number $i'),
          ],
          credits: [
            credit('c', bank: 'A bank with an unusually long name'),
          ],
          ibans: [iban(1)],
        );
        Get.put<HomeController>(home);
        await pumpApp(tester, Scaffold(body: WalletHome(controller: home)),
            mode: mode, locale: const Locale('de', 'DE'));
        await tester.drag(
            find.byType(CustomScrollView), const Offset(0, -1500));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('order and folders', () {
    final items = mergeAndSort(
      credits: [
        credit('c1', bank: 'Zeta Bank', tags: ['work'])
      ],
      ibans: [
        iban(1, bank: 'Alpha Bank', tags: ['family'])
      ],
      loyalties: [
        loyalty('a', 'Market', tags: ['family']),
        loyalty('b', 'Bakery', tags: [kFavoriteTag]),
      ],
    );
    List<String> names(List<WalletItem> l) =>
        [for (final i in l) titleForItem(i)];

    test('name order is A to Z across kinds', () {
      expect(names(stackOrder(items, HomeFilter.all, sort: HomeSort.name)),
          ['Alpha Bank', 'Bakery', 'Market', 'Zeta Bank']);
    });

    test('my order follows the saved list, new cards on top', () {
      final byName = {for (final i in items) titleForItem(i): i.heroTag};
      final manual = [
        byName['Zeta Bank']!,
        byName['Market']!,
        byName['Bakery']!
      ];
      expect(
          names(stackOrder(items, HomeFilter.all,
              sort: HomeSort.manual, manualOrder: manual)),
          ['Alpha Bank', 'Zeta Bank', 'Market', 'Bakery']);
    });

    test('a folder keeps its cards; favourites are a folder too', () {
      expect(names(stackOrder(items, HomeFilter.all, folder: 'family')),
          containsAll(['Market', 'Alpha Bank']));
      expect(stackOrder(items, HomeFilter.all, folder: 'family'), hasLength(2));
      expect(names(stackOrder(items, HomeFilter.all, folder: kFavoriteTag)),
          ['Bakery']);
      expect(walletFolders(items), [kFavoriteTag, 'family', 'work']);
    });

    testWidgets('folder chips narrow the wallet and clear again',
        (tester) async {
      await pumpHome(
          tester,
          FakeHome(
            loyalties: [
              loyalty('a', 'Market', tags: ['family']),
              loyalty('b', 'Bakery'),
            ],
            credits: [
              credit('c', bank: 'Chase', tags: ['work'])
            ],
          ));
      expect(find.byKey(const ValueKey('folder_family')), findsOneWidget);
      expect(find.byKey(const ValueKey('folder_work')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('folder_family')));
      await tester.pumpAndSettle();
      expect(find.text('Market'), findsWidgets);
      expect(find.text('Bakery'), findsNothing);
      expect(find.text('Chase'), findsNothing);
      // Up Next is about the whole wallet, not a folder.
      expect(find.byKey(const ValueKey('homeUpNext')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('folder_family')));
      await tester.pumpAndSettle();
      expect(find.text('Bakery'), findsWidgets);
    });

    testWidgets('the order sheet switches to A to Z', (tester) async {
      await pumpHome(
          tester,
          FakeHome(loyalties: [
            loyalty('a', 'Market'),
            loyalty('b', 'Bakery'),
          ]));
      await tester.tap(find.byKey(const ValueKey('homeSortButton')));
      await tester.pumpAndSettle();
      await tapIo(tester, find.byKey(const ValueKey('sort_name')));
      expect(UiPrefs.instance.homeSort.value, 'name');
      expect(find.byType(ReorderCardsPage), findsNothing);
    });

    testWidgets('dragging in Edit order saves my order', (tester) async {
      await pumpHome(
          tester,
          FakeHome(loyalties: [
            loyalty('a', 'Market'),
            loyalty('b', 'Bakery'),
            loyalty('c', 'Cinema'),
          ]));
      await tester.tap(find.byKey(const ValueKey('homeSortButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('sortEditOrder')));
      await tester.pumpAndSettle();
      expect(find.byType(ReorderCardsPage), findsOneWidget);
      expect(UiPrefs.instance.homeSort.value, 'manual');

      final before = UiPrefs.instance.manualOrder.toList();
      expect(before, hasLength(3));
      final handle = find.descendant(
          of: find.byKey(ValueKey(before.first)),
          matching: find.byType(ReorderableDragStartListener));
      await tester.drag(handle, const Offset(0, 200));
      await tester.pumpAndSettle();
      final after = UiPrefs.instance.manualOrder.toList();
      expect(after.first, isNot(before.first));
      expect(after.toSet(), before.toSet());
    });
  });
}
