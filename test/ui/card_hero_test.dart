import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/ui/navigation/card_hero.dart';

void main() {
  Widget card() => const Hero(
        tag: 'card',
        flightShuttleBuilder: cardHeroShuttle,
        child: Text('Everyday'),
      );

  testWidgets('a card in flight keeps the app text style (no yellow underline)',
      (tester) async {
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: nav,
      home: Scaffold(body: Center(child: card())),
    ));
    nav.currentState!.push(MaterialPageRoute<void>(
      builder: (_) =>
          Scaffold(body: Align(alignment: Alignment.topLeft, child: card())),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120)); // mid-flight
    final texts = find.text('Everyday').evaluate();
    expect(texts, isNotEmpty);
    for (final e in texts) {
      final style = DefaultTextStyle.of(e).style;
      expect(style.decoration, isNot(TextDecoration.underline),
          reason: 'flying text fell back to the debug style');
    }
  });
}
