import 'package:flutter/foundation.dart';
import 'package:wallet_app/core/services/rate_app_service.dart';
import 'package:wallet_app/core/utils/pin_setup_prompt.dart';
import 'package:wallet_app/core/utils/widget_setup_prompt.dart';

/// At most one unsolicited prompt (PIN nudge, widget tutorial, rating) per
/// app session, so a card save never stacks three dialogs on top of each
/// other.
class SessionPromptGate {
  SessionPromptGate._();

  static bool _used = false;

  static bool get isUsed => _used;

  static void markUsed() => _used = true;

  @visibleForTesting
  static void reset() => _used = false;
}

/// Post-save prompts in priority order: PIN > widget tutorial > rating.
/// The first one that actually shows consumes the session's prompt.
class PostAddPrompts {
  PostAddPrompts({
    Future<bool> Function(int total)? pinPrompt,
    Future<bool> Function(int loyaltyCount)? widgetPrompt,
    Future<bool> Function()? ratingPrompt,
  })  : _pinPrompt = pinPrompt ??
            ((total) => maybePromptPinSetup(totalCardCountAfterAdd: total)),
        _widgetPrompt = widgetPrompt ??
            ((count) => maybePromptWidgetSetup(loyaltyCountAfterAdd: count)),
        _ratingPrompt = ratingPrompt ??
            (() => RateAppService.instance
                .requestAfterMilestone(milestone: 'third_card_added'));

  final Future<bool> Function(int total) _pinPrompt;
  final Future<bool> Function(int loyaltyCount) _widgetPrompt;
  final Future<bool> Function() _ratingPrompt;

  /// [loyaltyCount] is only passed when the saved card is a loyalty card.
  Future<void> run({required int totalCards, int? loyaltyCount}) async {
    if (SessionPromptGate.isUsed) return;
    if (await _pinPrompt(totalCards)) return SessionPromptGate.markUsed();
    if (loyaltyCount != null && await _widgetPrompt(loyaltyCount)) {
      return SessionPromptGate.markUsed();
    }
    if (totalCards >= 3 && await _ratingPrompt()) {
      return SessionPromptGate.markUsed();
    }
  }
}
