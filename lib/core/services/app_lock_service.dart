import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wallet_app/core/data/local_services/auth_services/authentication_service.dart';
import 'package:wallet_app/core/data/local_services/auth_services/biometric_service.dart';
import 'package:wallet_app/core/router/getx_routes.dart';
import 'package:wallet_app/feature/auth/authentication_page.dart';

/// Re-locks the app when it comes back from the background.
///
/// The cold-launch PIN gate lives in the splash → /auth flow and is not
/// touched here. This service only covers the *warm* case: the user unlocked
/// once, sent the app to the background, and came back later.
///
/// Decision rules:
/// - Only `hidden` / `paused` start the background clock. iOS Face ID and the
///   StoreKit sheet only produce `inactive`, so they never trigger a lock.
/// - Flows that leave the app on purpose (camera, file picker, share sheet,
///   wallet, purchase, settings, browser) run inside [suppressWhile]. A
///   background that starts while suppressed waits at least
///   [suppressedGrace] (60 s) before it locks, so a quick round-trip to the
///   picker doesn't lock, but staying in the browser / store / share target
///   for longer than a minute does — even with "Immediately".
/// - Locks only when a PIN exists and the session was unlocked. If the
///   session was never unlocked, the user is already on the PIN screen or
///   on the read-only widget barcode page.
class AppLockService extends GetxService with WidgetsBindingObserver {
  AppLockService({
    DateTime Function()? clock,
    bool Function()? hasPassword,
    Future<int> Function()? loadAutoLockSeconds,
    Future<void> Function(AppLockService service)? presentLock,
  })  : _clock = clock ?? DateTime.now,
        _hasPassword =
            hasPassword ?? (() => AuthenticationService().hasPasswordSync()),
        _loadAutoLockSeconds = loadAutoLockSeconds ??
            (() => BiometricService().getAutoLockSeconds()),
        _presentLock = presentLock ?? _pushLockScreen;

  static AppLockService? get maybeInstance =>
      Get.isRegistered<AppLockService>() ? Get.find<AppLockService>() : null;

  /// Convenience wrapper for call sites: [suppressWhile] when the service is
  /// registered, otherwise just runs [action].
  static Future<T> guard<T>(Future<T> Function() action) {
    final service = maybeInstance;
    return service == null ? action() : service.suppressWhile(action);
  }

  /// Minimum time a suppressed background (picker, share sheet, store…)
  /// gets before the lock fires. The effective delay is the larger of this
  /// and the user's auto-lock setting. Kept short: with "Immediately", every
  /// extra second here is time the wallet sits unlocked in another app.
  static const Duration suppressedGrace = Duration(seconds: 60);

  /// Some plugins (launchUrl, openAppSettings) complete their future before
  /// the OS actually pauses the app. Keep suppression alive for a short tail.
  static const Duration suppressionTail = Duration(seconds: 2);

  final DateTime Function() _clock;
  final bool Function() _hasPassword;
  final Future<int> Function() _loadAutoLockSeconds;
  final Future<void> Function(AppLockService service) _presentLock;

  /// Auto-lock delay in seconds. 0 = lock immediately.
  final autoLockSeconds = BiometricService.defaultAutoLockSeconds.obs;

  bool _sessionUnlocked = false;
  bool _lockVisible = false;
  DateTime? _backgroundedAt;
  bool _backgroundedWhileSuppressed = false;
  int _suppressDepth = 0;
  DateTime? _suppressUntil;
  Route<dynamic>? _lockRoute;

  /// True while the lock screen is on top of the navigator.
  bool get isLockVisible => _lockVisible;

  /// True when sensitive content must not be shown: a PIN exists and the
  /// user has not unlocked this session (or a re-lock is pending).
  bool get isLocked => _hasPassword() && (!_sessionUnlocked || _lockVisible);

  bool get isSuppressed {
    if (_suppressDepth > 0) return true;
    final until = _suppressUntil;
    return until != null && _clock().isBefore(until);
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    unawaited(reloadAutoLockSeconds());
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  Future<void> reloadAutoLockSeconds() async {
    try {
      autoLockSeconds.value = await _loadAutoLockSeconds();
    } catch (_) {
      autoLockSeconds.value = BiometricService.defaultAutoLockSeconds;
    }
  }

  /// Called after any successful PIN / biometric / recovery unlock and when
  /// the user creates a PIN from inside the app.
  void markUnlocked() {
    _sessionUnlocked = true;
    _backgroundedAt = null;
  }

  /// Runs [action] (camera, picker, share sheet, purchase, external URL…)
  /// without the round-trip to another app counting as "left the app".
  Future<T> suppressWhile<T>(Future<T> Function() action) async {
    _suppressDepth++;
    try {
      return await action();
    } finally {
      _suppressDepth--;
      if (_suppressDepth == 0) {
        _suppressUntil = _clock().add(suppressionTail);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    handleLifecycle(state);
  }

  @visibleForTesting
  void handleLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        if (_backgroundedAt == null) {
          _backgroundedAt = _clock();
          _backgroundedWhileSuppressed = isSuppressed;
        }
        break;
      case AppLifecycleState.resumed:
        final shouldLock = shouldLockNow();
        _backgroundedAt = null;
        _backgroundedWhileSuppressed = false;
        if (shouldLock) unawaited(lock());
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  /// Pure decision for the resume event; exposed for tests.
  @visibleForTesting
  bool shouldLockNow() {
    final since = _backgroundedAt;
    if (since == null) return false;
    if (_lockVisible || !_sessionUnlocked) return false;
    if (!_hasPassword()) return false;
    var threshold = Duration(seconds: autoLockSeconds.value);
    if (_backgroundedWhileSuppressed && threshold < suppressedGrace) {
      threshold = suppressedGrace;
    }
    return _clock().difference(since) >= threshold;
  }

  /// Shows the lock screen on top of the current route. No-op when it's
  /// already visible.
  Future<void> lock() async {
    if (_lockVisible) return;
    _lockVisible = true;
    _sessionUnlocked = false;
    try {
      await _presentLock(this);
    } finally {
      _lockVisible = false;
      _lockRoute = null;
    }
  }

  /// Pops the lock screen after a successful unlock. Returns false when no
  /// lock screen was showing (cold-launch flow handles its own routing).
  bool dismissLockScreen() {
    markUnlocked();
    final route = _lockRoute;
    if (!_lockVisible || route == null) return false;
    final navigator = route.navigator;
    if (navigator != null && route.isActive) {
      if (route.isCurrent) {
        navigator.pop();
      } else {
        navigator.removeRoute(route);
      }
    }
    return true;
  }

  static Future<void> _pushLockScreen(AppLockService service) async {
    final navigator = Get.key.currentState;
    if (navigator == null) return;
    // The cold-launch flow is still in charge on these routes.
    const coldRoutes = {AppRoutes.splash, AppRoutes.auth, AppRoutes.onboarding};
    if (coldRoutes.contains(Get.currentRoute)) return;

    FocusManager.instance.primaryFocus?.unfocus();
    final route = PageRouteBuilder<void>(
      settings: const RouteSettings(name: AppRoutes.unlock),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) => const AuthenticationPage(unlockMode: true),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );
    service._lockRoute = route;
    await navigator.push(route);
  }
}
