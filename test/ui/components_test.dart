import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/ui/components/cw_list.dart';
import 'package:wallet_app/ui/components/cw_misc.dart';

import '../helpers/harness.dart';

void main() {
  final h = Harness();
  setUp(h.setUp);
  tearDown(h.tearDown);

  testWidgets('tapping anywhere on a switch row toggles it', (tester) async {
    var on = false;
    await pumpApp(
      tester,
      Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => CwGroup(children: [
            CwRow(
              title: 'Up Next',
              trailing: CwSwitch(
                value: on,
                onChanged: (v) => setState(() => on = v),
              ),
            ),
          ]),
        ),
      ),
    );
    await tester.tap(find.text('Up Next'));
    await tester.pump();
    expect(on, isTrue);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(on, isFalse);
  });

  testWidgets('a row with its own onTap keeps it', (tester) async {
    var taps = 0;
    var toggled = false;
    await pumpApp(
      tester,
      Scaffold(
        body: CwRow(
          title: 'Payment due',
          onTap: () => taps++,
          trailing: CwSwitch(value: false, onChanged: (_) => toggled = true),
        ),
      ),
    );
    await tester.tap(find.text('Payment due'));
    await tester.pump();
    expect(taps, 1);
    expect(toggled, isFalse);
  });

  testWidgets('switch is Cupertino on iOS, Material elsewhere', (tester) async {
    Widget sw(TargetPlatform p) => Theme(
          data: ThemeData(platform: p),
          child: CwSwitch(value: true, onChanged: (_) {}),
        );
    await pumpApp(tester, Scaffold(body: sw(TargetPlatform.iOS)));
    expect(find.byType(CupertinoSwitch), findsOneWidget);
    await pumpApp(tester, Scaffold(body: sw(TargetPlatform.android)));
    expect(find.byType(CupertinoSwitch), findsNothing);
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('a grouped menu in a sheet is as tall as its rows',
      (tester) async {
    await phoneSurface(tester);
    await pumpApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showCwSheet<void>(
              context,
              builder: (_) => CwGroup(children: [
                for (final t in ['One', 'Two', 'Three'])
                  CwRow(title: t, onTap: () {}),
              ]),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final sheet = find.byType(BottomSheet);
    expect(tester.getSize(sheet).height, lessThan(260));
  });

  testWidgets('choice sheet returns the picked value; dismiss returns null',
      (tester) async {
    String? picked = 'unset';
    await pumpApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              picked = await showCwChoiceSheet<String>(
                context,
                title: 'Theme',
                selected: 'dark',
                options: const [
                  CwChoice('light', 'Light'),
                  CwChoice('dark', 'Dark'),
                ],
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(picked, 'light');

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(picked, isNull);
  });

  testWidgets('segmented control reports the tapped value', (tester) async {
    var sel = 1;
    await pumpApp(
      tester,
      Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => CwSegmented<int>(
            values: const [1, 2, 3],
            selected: sel,
            label: (v) => 'Seg $v',
            onChanged: (v) => setState(() => sel = v),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Seg 3'));
    await tester.pumpAndSettle();
    expect(sel, 3);
  });
}
