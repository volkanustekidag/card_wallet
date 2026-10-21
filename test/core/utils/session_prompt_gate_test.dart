import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/utils/session_prompt_gate.dart';

void main() {
  late List<String> shown;

  PostAddPrompts prompts({
    bool pin = false,
    bool widget = false,
    bool rating = false,
  }) =>
      PostAddPrompts(
        pinPrompt: (_) async {
          if (pin) shown.add('pin');
          return pin;
        },
        widgetPrompt: (_) async {
          if (widget) shown.add('widget');
          return widget;
        },
        ratingPrompt: () async {
          if (rating) shown.add('rating');
          return rating;
        },
      );

  setUp(() {
    shown = [];
    SessionPromptGate.reset();
  });

  test('PIN wins over widget and rating', () async {
    await prompts(pin: true, widget: true, rating: true)
        .run(totalCards: 3, loyaltyCount: 1);
    expect(shown, ['pin']);
  });

  test('widget wins over rating when PIN is not due', () async {
    await prompts(widget: true, rating: true)
        .run(totalCards: 3, loyaltyCount: 1);
    expect(shown, ['widget']);
  });

  test('rating only at the 3-card milestone', () async {
    await prompts(rating: true).run(totalCards: 2);
    expect(shown, isEmpty);
    await prompts(rating: true).run(totalCards: 3);
    expect(shown, ['rating']);
  });

  test('only one prompt per session', () async {
    await prompts(pin: true).run(totalCards: 1);
    await prompts(widget: true, rating: true)
        .run(totalCards: 3, loyaltyCount: 1);
    expect(shown, ['pin']);
  });

  test('widget prompt is skipped for non-loyalty saves', () async {
    await prompts(widget: true).run(totalCards: 1);
    expect(shown, isEmpty);
    expect(SessionPromptGate.isUsed, isFalse);
  });
}
