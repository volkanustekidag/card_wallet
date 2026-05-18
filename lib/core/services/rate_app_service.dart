import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

/// Schedules and triggers the native in-app review prompt and routes manual
/// "Rate App" taps to the right store for the current platform.
///
/// The OS rate-limits the native prompt (Apple shows it at most 3 times per
/// 365 days, Play has its own quota), so the eligibility gate below is
/// intentionally conservative on top of that.
class RateAppService {
  RateAppService._();
  static final RateAppService instance = RateAppService._();

  static const String _boxName = 'rate_app_box';
  static const String _kFirstLaunch = 'first_launch_ms';
  static const String _kSessionCount = 'session_count';
  static const String _kLastPromptAt = 'last_prompt_ms';

  static const String _appStoreId = '6755343533';
  static const String _androidPackageName = 'com.volkan.wallet_app';

  static const int _minSessions = 4;
  static const int _minDaysSinceInstall = 3;
  static const int _minDaysBetweenPrompts = 60;
  static const Duration _initialPromptDelay = Duration(seconds: 6);

  final InAppReview _review = InAppReview.instance;
  Box? _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!_box!.containsKey(_kFirstLaunch)) {
      await _box!.put(_kFirstLaunch, now);
    }
    final next = (_box!.get(_kSessionCount, defaultValue: 0) as int) + 1;
    await _box!.put(_kSessionCount, next);
  }

  /// Schedules a delayed eligibility check so the prompt never collides with
  /// splash / lock-screen frames.
  void scheduleInitialPrompt() {
    Future.delayed(_initialPromptDelay, maybeRequestReview);
  }

  Future<void> maybeRequestReview() async {
    final box = _box;
    if (box == null) return;

    final firstLaunchMs = box.get(_kFirstLaunch) as int?;
    if (firstLaunchMs == null) return;

    final sessions = box.get(_kSessionCount, defaultValue: 0) as int;
    final lastPromptMs = box.get(_kLastPromptAt) as int?;
    final now = DateTime.now();

    final daysSinceInstall = now
        .difference(DateTime.fromMillisecondsSinceEpoch(firstLaunchMs))
        .inDays;
    if (daysSinceInstall < _minDaysSinceInstall) return;
    if (sessions < _minSessions) return;

    if (lastPromptMs != null) {
      final lastPrompt = DateTime.fromMillisecondsSinceEpoch(lastPromptMs);
      if (now.difference(lastPrompt).inDays < _minDaysBetweenPrompts) {
        return;
      }
    }

    try {
      if (!await _review.isAvailable()) return;
      await box.put(_kLastPromptAt, now.millisecondsSinceEpoch);
      await _review.requestReview();
    } catch (e, st) {
      debugPrint('RateAppService.requestReview failed: $e\n$st');
    }
  }

  /// Routes the user to the platform store. Used by the manual "Rate App"
  /// button in settings — bypasses the OS quota that limits requestReview.
  Future<void> openStoreListing() async {
    try {
      await _review.openStoreListing(appStoreId: _appStoreId);
      return;
    } catch (e) {
      debugPrint('RateAppService.openStoreListing fallback: $e');
    }

    final fallback = Platform.isIOS
        ? Uri.parse('https://apps.apple.com/app/id$_appStoreId')
        : Uri.parse(
            'https://play.google.com/store/apps/details?id=$_androidPackageName',
          );
    await launchUrl(fallback, mode: LaunchMode.externalApplication);
  }
}
