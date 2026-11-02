import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet_app/core/services/analytics_service.dart';
import 'package:wallet_app/core/services/app_lock_service.dart';
import 'package:wallet_app/core/utils/session_prompt_gate.dart';

/// Triggers the native in-app review prompt at success moments and routes
/// manual "Rate App" taps to the right store for the current platform.
///
/// The OS rate-limits the native prompt (Apple shows it at most 3 times per
/// 365 days, Play has its own quota), so it is only asked right after the
/// app has just worked for the user: a card shown at the till and closed
/// again, or the third card saved. Never on launch or resume: the app is
/// often opened at the till, and a dialog over the barcode is the worst
/// moment there is.
class RateAppService {
  RateAppService._();
  static final RateAppService instance = RateAppService._();

  static const String _boxName = 'rate_app_box';
  static const String _kFirstLaunch = 'first_launch_ms';
  static const String _kLastPromptAt = 'last_prompt_ms';
  static const String _kCheckoutShows = 'checkout_shows';

  static const String _appStoreId = '6755343533';
  static const String _androidPackageName = 'com.volkan.wallet_app';

  static const int _minDaysBetweenPrompts = 60;

  /// A checkout counts once the barcode was up this long (a scan, not a peek).
  static const Duration minCheckoutShown = Duration(seconds: 3);

  /// Checkouts before the first ask, and days since install.
  static const int checkoutsBeforeAsking = 3;
  static const int minDaysSinceInstall = 2;

  /// Lets the card's close animation finish before the system sheet appears.
  static const Duration _afterCloseDelay = Duration(milliseconds: 800);

  final InAppReview _review = InAppReview.instance;
  Box? _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!_box!.containsKey(_kFirstLaunch)) {
      await _box!.put(_kFirstLaunch, now);
    }
    final firstLaunchMs = _box!.get(_kFirstLaunch, defaultValue: now) as int;
    final daysSinceInstall = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(firstLaunchMs))
        .inDays;
    unawaited(
      AnalyticsService.instance.setDaysSinceInstall(daysSinceInstall),
    );
  }

  /// Whether closing a checkout should ask for a rating: the barcode was up
  /// long enough to be scanned, this is at least the [checkoutsBeforeAsking]th
  /// such checkout, and the app has been installed for a couple of days.
  @visibleForTesting
  static bool shouldAskAfterCheckout({
    required Duration shownFor,
    required int checkouts,
    required int daysSinceInstall,
  }) =>
      shownFor >= minCheckoutShown &&
      checkouts >= checkoutsBeforeAsking &&
      daysSinceInstall >= minDaysSinceInstall;

  /// Success-moment path: a loyalty card's checkout was just closed after
  /// [shownFor] on screen. Counts real checkouts and, from the third on,
  /// asks once the card has animated away.
  Future<void> onCheckoutClosed(Duration shownFor) async {
    final box = _box;
    if (box == null || shownFor < minCheckoutShown) return;
    final checkouts = (box.get(_kCheckoutShows, defaultValue: 0) as int) + 1;
    await box.put(_kCheckoutShows, checkouts);
    final firstLaunchMs = box.get(_kFirstLaunch) as int?;
    if (firstLaunchMs == null) return;
    final daysSinceInstall = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(firstLaunchMs))
        .inDays;
    if (!shouldAskAfterCheckout(
      shownFor: shownFor,
      checkouts: checkouts,
      daysSinceInstall: daysSinceInstall,
    )) {
      return;
    }
    await Future<void>.delayed(_afterCloseDelay);
    await _attemptReview(source: 'milestone', milestone: 'checkout_used');
  }

  /// Success-moment path: fired after a positive user action (e.g. the
  /// third card added); reaching it is a strong happiness signal on its own. Still respects the 60-day window between
  /// prompts and the OS-level quota — Apple silently rate-limits to ~3
  /// shows per 365 days regardless of what we do, so spamming this would
  /// just burn the user's remaining quota with no benefit.
  /// Returns true when the review prompt was requested.
  Future<bool> requestAfterMilestone({required String milestone}) {
    return _attemptReview(source: 'milestone', milestone: milestone);
  }

  Future<bool> _attemptReview({
    required String source,
    String? milestone,
  }) async {
    final box = _box;
    if (box == null) return false;
    // Another prompt (PIN nudge, widget tutorial) already ran this session.
    if (SessionPromptGate.isUsed) return false;

    final now = DateTime.now();
    final lastPromptMs = box.get(_kLastPromptAt) as int?;
    if (lastPromptMs != null) {
      final lastPrompt = DateTime.fromMillisecondsSinceEpoch(lastPromptMs);
      if (now.difference(lastPrompt).inDays < _minDaysBetweenPrompts) {
        return false;
      }
    }

    try {
      if (!await _review.isAvailable()) return false;
      SessionPromptGate.markUsed();
      // Write the timestamp *before* the prompt so a crash between
      // requestReview() and the next launch still counts as "we tried" —
      // better to under-prompt than to spam on retry.
      await box.put(_kLastPromptAt, now.millisecondsSinceEpoch);
      unawaited(
        AnalyticsService.instance.logRatePromptShown(
          source: source,
          milestone: milestone,
        ),
      );
      await _review.requestReview();
      return true;
    } catch (e, st) {
      debugPrint('RateAppService._attemptReview failed: $e\n$st');
      return false;
    }
  }

  /// Routes the user to the platform store. Used by the manual "Rate App"
  /// button in settings — bypasses the OS quota that limits requestReview.
  Future<void> openStoreListing() async {
    try {
      await AppLockService.guard(() => _review.openStoreListing(appStoreId: _appStoreId));
      return;
    } catch (e) {
      debugPrint('RateAppService.openStoreListing fallback: $e');
    }

    final fallback = Platform.isIOS
        ? Uri.parse('https://apps.apple.com/app/id$_appStoreId')
        : Uri.parse(
            'https://play.google.com/store/apps/details?id=$_androidPackageName',
          );
    await AppLockService.guard(() => launchUrl(fallback, mode: LaunchMode.externalApplication));
  }
}
