import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper around FirebaseAnalytics so the rest of the app never imports
/// the SDK directly. Failures are swallowed in release — analytics must never
/// take down a screen.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> setEnabled(bool enabled) async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(enabled);
    } catch (e, s) {
      _swallow(e, s);
    }
  }

  Future<void> logEvent(String name, {Map<String, Object>? params}) async {
    try {
      await _analytics.logEvent(name: name, parameters: params);
    } catch (e, s) {
      _swallow(e, s);
    }
  }

  Future<void> logScreen(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e, s) {
      _swallow(e, s);
    }
  }

  Future<void> setUserProperty(String name, String? value) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e, s) {
      _swallow(e, s);
    }
  }

  void _swallow(Object e, StackTrace s) {
    if (kDebugMode) {
      debugPrint('AnalyticsService error: $e\n$s');
    }
  }
}
