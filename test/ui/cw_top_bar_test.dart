import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/ui/components/cw_top_bar.dart';

import '../helpers/harness.dart';

void main() {
  final h = Harness();
  setUp(h.setUp);
  tearDown(h.tearDown);

  Future<void> pumpPage(WidgetTester tester, {bool inline = false}) async {
    await phoneSurface(tester);
    await pumpApp(
      tester,
      Scaffold(
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            CwLargeTitleBar(
              title: 'Settings',
              inline: inline,
              leading: inline ? null : const Icon(Icons.arrow_back),
              actions: [const Icon(Icons.search, key: ValueKey('action'))],
            ),
            SliverList.list(children: [
              for (var i = 0; i < 40; i++)
                SizedBox(height: 60, child: Text('Row $i')),
            ]),
          ],
        ),
      ),
    );
  }

  /// Rendered title height over its laid-out height.
  double titleScale(WidgetTester tester) {
    final title = find.text('Settings');
    return tester.getRect(title).height / tester.getSize(title).height;
  }

  Offset titleCenter(WidgetTester tester) =>
      tester.getCenter(find.text('Settings'));

  testWidgets('large title shrinks into the centre of the bar', (tester) async {
    await pumpPage(tester);
    expect(titleScale(tester), 1);
    final rest = titleCenter(tester);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(titleScale(tester), closeTo(17 / 34, 0.01));
    final collapsed = titleCenter(tester);
    expect(collapsed.dy, lessThan(rest.dy));
    // Centred between the bar buttons.
    expect(
        tester.getRect(find.text('Settings')).center.dx, greaterThan(rest.dx));
    // The bar is pinned: its buttons stay on screen.
    expect(tester.getTopLeft(find.byKey(const ValueKey('action'))).dy,
        lessThan(60));
    expect(tester.takeException(), isNull);
  });

  testWidgets('inline title shrinks in place and the bar stays put',
      (tester) async {
    await pumpPage(tester, inline: true);
    final restY = titleCenter(tester).dy;
    final actionY = tester.getCenter(find.byKey(const ValueKey('action'))).dy;

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(titleScale(tester), closeTo(22 / 34, 0.01));
    expect(titleCenter(tester).dy, closeTo(restY, 1));
    expect(tester.getCenter(find.byKey(const ValueKey('action'))).dy, actionY);
  });

  testWidgets('pulling down grows the title a little', (tester) async {
    await pumpPage(tester);
    final gesture =
        await tester.startGesture(tester.getCenter(find.text('Row 3')));
    await gesture.moveBy(const Offset(0, 120));
    await tester.pump();
    expect(titleScale(tester), greaterThan(1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(titleScale(tester), 1);
  });

  testWidgets('scroll edge hairline appears once the body scrolls',
      (tester) async {
    await phoneSurface(tester);
    await pumpApp(
      tester,
      Scaffold(
        body: CwScrollEdge(
          bar: const SizedBox(height: 50, child: Text('Bar')),
          body: ListView(children: [
            for (var i = 0; i < 40; i++)
              SizedBox(height: 60, child: Text('Row $i')),
          ]),
        ),
      ),
    );
    Color line() {
      final box = tester.widget<AnimatedContainer>(find.ancestor(
          of: find.text('Bar'), matching: find.byType(AnimatedContainer)));
      return ((box.decoration! as BoxDecoration).border! as Border)
          .bottom
          .color;
    }

    expect(line().a, 0);
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(line().a, greaterThan(0));
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(line().a, 0);
  });
}
