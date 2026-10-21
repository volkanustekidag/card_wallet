import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wallet_app/core/services/error_reporter.dart';
import 'package:wallet_app/core/utils/secure_storage_provider.dart';

/// Full brightness + screen kept on while a barcode is on screen, so the
/// cashier's scanner reads it first time. Restores the user's brightness and
/// normal sleep when the last barcode view closes.
///
/// Uses the *application* brightness (window-level), never the system
/// setting, so the OS restores it on its own if the app is killed.
/// Reference-counted: the detail page and the detail sheet can overlap.
class BarcodeDisplayBoost {
  BarcodeDisplayBoost({
    Future<void> Function()? boost,
    Future<void> Function()? restore,
    Future<String?> Function()? readSetting,
    Future<void> Function(String value)? writeSetting,
  })  : _boost = boost ?? _platformBoost,
        _restore = restore ?? _platformRestore,
        _readSetting = readSetting ??
            (() => SecureStorageProvider.instance.read(key: _settingKey)),
        _writeSetting = writeSetting ??
            ((value) => SecureStorageProvider.instance
                .write(key: _settingKey, value: value));

  static final BarcodeDisplayBoost instance = BarcodeDisplayBoost();

  static const String _settingKey = 'barcode_display_boost';

  final Future<void> Function() _boost;
  final Future<void> Function() _restore;
  final Future<String?> Function() _readSetting;
  final Future<void> Function(String value) _writeSetting;

  /// Settings toggle; on by default.
  final enabled = true.obs;
  bool _loaded = false;
  int _holders = 0;
  bool _active = false;

  static Future<void> _platformBoost() async {
    await ScreenBrightness.instance.setApplicationScreenBrightness(1.0);
    await WakelockPlus.enable();
  }

  static Future<void> _platformRestore() async {
    await ScreenBrightness.instance.resetApplicationScreenBrightness();
    await WakelockPlus.disable();
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      enabled.value = (await _readSetting()) != 'false';
    } catch (_) {
      enabled.value = true;
    }
  }

  Future<void> setEnabled(bool value) async {
    await _ensureLoaded();
    enabled.value = value;
    try {
      await _writeSetting(value ? 'true' : 'false');
    } catch (_) {}
    if (!value && _active) {
      await _apply(false);
    } else if (value && _holders > 0 && !_active) {
      await _apply(true);
    }
  }

  /// Call when a barcode view appears.
  Future<void> acquire() async {
    _holders++;
    await _ensureLoaded();
    if (_holders > 0 && enabled.value && !_active) await _apply(true);
  }

  /// Call when that view goes away.
  Future<void> release() async {
    if (_holders == 0) return;
    _holders--;
    if (_holders == 0 && _active) await _apply(false);
  }

  Future<void> _apply(bool on) async {
    _active = on;
    try {
      await (on ? _boost() : _restore());
    } catch (e, st) {
      ErrorReporter.report(e, st, reason: 'BarcodeDisplayBoost');
    }
  }

  @visibleForTesting
  bool get isActive => _active;
}
