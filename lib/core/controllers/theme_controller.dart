import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

enum AppThemeMode { light, dark, system }

class ThemeController extends GetxController {
  static const String _boxName = 'theme_box';
  static const String _modeKey = 'themeMode';
  static const String _legacyDarkKey = 'isDarkMode';

  final Rx<AppThemeMode> _themeMode;
  Box? _themeBox;

  ThemeController({AppThemeMode initialMode = AppThemeMode.system, Box? box})
      : _themeMode = initialMode.obs,
        _themeBox = box;

  AppThemeMode get appThemeMode => _themeMode.value;

  bool get isDarkMode {
    switch (_themeMode.value) {
      case AppThemeMode.light:
        return false;
      case AppThemeMode.dark:
        return true;
      case AppThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    }
  }

  ThemeMode get themeMode {
    switch (_themeMode.value) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  /// Resolve the persisted theme mode synchronously *before* runApp so
  /// MaterialApp can build with the correct theme on the very first frame.
  /// Returns the parsed mode and keeps the open box reference so the
  /// controller doesn't have to reopen it.
  static Future<({AppThemeMode mode, Box box})> bootstrap() async {
    final box = await Hive.openBox(_boxName);
    final stored = box.get(_modeKey) as String?;
    AppThemeMode mode;
    if (stored != null) {
      mode = _parse(stored);
    } else {
      final legacyDark = box.get(_legacyDarkKey) as bool?;
      if (legacyDark == true) {
        mode = AppThemeMode.dark;
      } else if (legacyDark == false) {
        mode = AppThemeMode.light;
      } else {
        mode = AppThemeMode.system;
      }
      await box.put(_modeKey, mode.name);
      await box.delete(_legacyDarkKey);
    }
    return (mode: mode, box: box);
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode.value == mode) return;
    _themeMode.value = mode;
    Get.changeThemeMode(themeMode);
    await _persist();
  }

  // Backward-compat: existing settings card uses a Switch
  void setDarkMode(bool value) {
    setThemeMode(value ? AppThemeMode.dark : AppThemeMode.light);
  }

  Future<void> _persist() async {
    try {
      _themeBox ??= await Hive.openBox(_boxName);
      await _themeBox?.put(_modeKey, _themeMode.value.name);
    } catch (e) {
      debugPrint('Theme save error: $e');
    }
  }

  static AppThemeMode _parse(String value) {
    switch (value) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
      default:
        return AppThemeMode.system;
    }
  }
}
