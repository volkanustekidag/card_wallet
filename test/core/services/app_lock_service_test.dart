import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/data/local_services/auth_services/biometric_service.dart';
import 'package:wallet_app/core/services/app_lock_service.dart';

class _FakeClock {
  DateTime now = DateTime(2026, 10, 21, 12);
  void advance(Duration d) => now = now.add(d);
}

void main() {
  late _FakeClock clock;
  late bool hasPassword;
  late int presentCount;
  late AppLockService service;

  AppLockService build({int autoLockSeconds = 30}) {
    final s = AppLockService(
      clock: () => clock.now,
      hasPassword: () => hasPassword,
      loadAutoLockSeconds: () async => autoLockSeconds,
      presentLock: (_) async => presentCount++,
    );
    s.autoLockSeconds.value = autoLockSeconds;
    return s;
  }

  void background() {
    service.handleLifecycle(AppLifecycleState.inactive);
    service.handleLifecycle(AppLifecycleState.hidden);
    service.handleLifecycle(AppLifecycleState.paused);
  }

  void resume() {
    service.handleLifecycle(AppLifecycleState.inactive);
    service.handleLifecycle(AppLifecycleState.resumed);
  }

  setUp(() {
    clock = _FakeClock();
    hasPassword = true;
    presentCount = 0;
    service = build();
    service.markUnlocked();
  });

  test('locks after the auto-lock delay in the background', () async {
    background();
    clock.advance(const Duration(seconds: 31));
    resume();
    await Future<void>.delayed(Duration.zero);
    expect(presentCount, 1);
    expect(service.isLocked, isTrue);
  });

  test('does not lock when back before the delay', () {
    background();
    clock.advance(const Duration(seconds: 10));
    resume();
    expect(presentCount, 0);
    expect(service.isLocked, isFalse);
  });

  test('"immediately" locks on any real background', () {
    service = build(autoLockSeconds: 0)..markUnlocked();
    background();
    resume();
    expect(presentCount, 1);
  });

  test('inactive alone (Face ID, StoreKit sheet) never locks', () {
    service = build(autoLockSeconds: 0)..markUnlocked();
    service.handleLifecycle(AppLifecycleState.inactive);
    clock.advance(const Duration(minutes: 10));
    service.handleLifecycle(AppLifecycleState.resumed);
    expect(presentCount, 0);
  });

  test('never locks without a PIN', () {
    hasPassword = false;
    background();
    clock.advance(const Duration(hours: 1));
    resume();
    expect(presentCount, 0);
    expect(service.isLocked, isFalse);
  });

  test('never locks a session that was not unlocked yet', () {
    service = build();
    background();
    clock.advance(const Duration(hours: 1));
    resume();
    expect(presentCount, 0);
    // Still locked from the cold-launch gate's point of view.
    expect(service.isLocked, isTrue);
  });

  test('suppressed round-trips (camera, share) get the grace period',
      () async {
    await service.suppressWhile(() async {
      background();
      clock.advance(const Duration(seconds: 45));
      resume();
    });
    expect(presentCount, 0);
  });

  test('grace period is 60 seconds', () {
    expect(AppLockService.suppressedGrace, const Duration(seconds: 60));
  });

  test('"Immediately" + suppressed background locks after 60 s', () async {
    service = build(autoLockSeconds: 0)..markUnlocked();
    await service.suppressWhile(() async {
      background();
      clock.advance(const Duration(seconds: 59));
      resume();
    });
    expect(presentCount, 0);

    await service.suppressWhile(() async {
      background();
      clock.advance(const Duration(seconds: 60));
      resume();
    });
    expect(presentCount, 1);
  });

  test('suppression tail covers plugins that return before the pause',
      () async {
    await service.suppressWhile(() async {});
    clock.advance(const Duration(milliseconds: 500));
    background();
    clock.advance(const Duration(seconds: 45));
    resume();
    expect(presentCount, 0);
  });

  test('a suppressed background still locks after the grace period',
      () async {
    await service.suppressWhile(() async {
      background();
      clock.advance(AppLockService.suppressedGrace);
      resume();
    });
    expect(presentCount, 1);
  });

  test('does not push the lock screen twice', () async {
    final completer = <Future<void>>[];
    service = AppLockService(
      clock: () => clock.now,
      hasPassword: () => true,
      loadAutoLockSeconds: () async => 0,
      presentLock: (_) {
        presentCount++;
        final f = Future<void>.delayed(const Duration(milliseconds: 10));
        completer.add(f);
        return f;
      },
    )
      ..autoLockSeconds.value = 0
      ..markUnlocked();
    background();
    resume();
    background();
    resume();
    expect(presentCount, 1);
    await Future.wait(completer);
  });

  test('dismissLockScreen marks the session unlocked', () async {
    service = build()..markUnlocked();
    background();
    clock.advance(const Duration(minutes: 1));
    resume();
    expect(service.isLocked, isTrue);
    service.dismissLockScreen();
    await Future<void>.delayed(Duration.zero);
    expect(service.isLocked, isFalse);
  });

  group('AutoLockTime', () {
    test('normalize snaps down to a supported option', () {
      expect(AutoLockTime.normalize(0), 0);
      expect(AutoLockTime.normalize(45), 30);
      expect(AutoLockTime.normalize(120), 60); // legacy 2 min
      expect(AutoLockTime.normalize(600), 300); // legacy 10 min
      expect(AutoLockTime.normalize(1800), 900); // legacy 30 min
      expect(AutoLockTime.normalize(-5), 0);
    });

    test('default is 30 seconds', () {
      expect(BiometricService.defaultAutoLockSeconds, 30);
    });
  });
}
