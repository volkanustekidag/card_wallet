import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class ThemeController extends GetxController {
  final _isDarkMode = false.obs;
  Box? _themeBox;

  bool get isDarkMode => _isDarkMode.value;
  ThemeMode get themeMode =>
      _isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  void _loadTheme() async {
    try {
      _themeBox = await Hive.openBox('theme_box');
      final savedTheme = _themeBox?.get('isDarkMode', defaultValue: false);
      _isDarkMode.value = savedTheme ?? false;
      Get.changeThemeMode(themeMode);
    } catch (e) {
      _isDarkMode.value = false;
      print('Theme yükleme hatası: $e');
    }
  }

  void toggleTheme() async {
    _isDarkMode.value = !_isDarkMode.value;
    Get.changeThemeMode(themeMode);
    await _saveTheme();
  }

  void setDarkMode(bool value) async {
    _isDarkMode.value = value;
    Get.changeThemeMode(themeMode);
    await _saveTheme();
  }

  Future<void> _saveTheme() async {
    try {
      await _themeBox?.put('isDarkMode', _isDarkMode.value);
    } catch (e) {
      print('Theme kaydetme hatası: $e');
    }
  }
}
