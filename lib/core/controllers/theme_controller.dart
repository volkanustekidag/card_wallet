import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

enum AppThemeMode { light, dark, system }

class ThemeController extends GetxController {
  final _themeMode = AppThemeMode.system.obs;
  Box? _themeBox;

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

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      _themeBox = await Hive.openBox('theme_box');
      final stored = _themeBox?.get('themeMode') as String?;
      if (stored != null) {
        _themeMode.value = _parse(stored);
      } else {
        final legacyDark = _themeBox?.get('isDarkMode') as bool?;
        if (legacyDark == true) {
          _themeMode.value = AppThemeMode.dark;
        } else if (legacyDark == false) {
          _themeMode.value = AppThemeMode.light;
        } else {
          _themeMode.value = AppThemeMode.system;
        }
        await _persist();
      }
      Get.changeThemeMode(themeMode);
    } catch (e) {
      _themeMode.value = AppThemeMode.system;
      debugPrint('Theme load error: $e');
    }
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
      await _themeBox?.put('themeMode', _themeMode.value.name);
      await _themeBox?.delete('isDarkMode');
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
