import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:wallet_app/core/utils/secure_storage_provider.dart';

// Theme Model
class ThemeModel {
  final bool isDarkMode;

  ThemeModel({required this.isDarkMode});

  Map<String, dynamic> toMap() {
    return {'isDarkMode': isDarkMode};
  }

  factory ThemeModel.fromMap(Map<String, dynamic> map) {
    return ThemeModel(isDarkMode: map['isDarkMode'] ?? false);
  }
}

// Theme Service
class ThemeService {
  Box? _themeBox;
  static const String THEME_BOX_NAME = 'theme_box';
  static const String THEME_SECURE_STORAGE_KEY = 'theme_secure_key';

  Future<void> init() async {
    bool boxExists = await Hive.boxExists(THEME_BOX_NAME);

    if (boxExists == false) {
      final secureKey = Hive.generateSecureKey();
      const secureStorage = SecureStorageProvider.instance;

      _themeBox = await Hive.openBox(THEME_BOX_NAME,
          encryptionCipher: HiveAesCipher(secureKey));

      await secureStorage.write(
          key: THEME_SECURE_STORAGE_KEY, value: json.encode(secureKey));
    }
  }

  Future<void> openBox() async {
    final secureKey = await SecureStorageProvider.instance
        .read(key: THEME_SECURE_STORAGE_KEY);

    if (secureKey != null) {
      List<int> encryptionKey =
          (json.decode(secureKey) as List<dynamic>).cast<int>();

      _themeBox = await Hive.openBox(
        THEME_BOX_NAME,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } else {
      _themeBox = await Hive.openBox(THEME_BOX_NAME);
    }
  }

  Future<bool> getThemeMode() async {
    if (_themeBox == null) await openBox();
    final themeData = _themeBox?.get('theme');
    if (themeData != null) {
      final themeModel =
          ThemeModel.fromMap(Map<String, dynamic>.from(themeData));
      return themeModel.isDarkMode;
    }
    return false; // Default light mode
  }

  Future<void> saveThemeMode(bool isDarkMode) async {
    if (_themeBox == null) await openBox();
    final themeModel = ThemeModel(isDarkMode: isDarkMode);
    await _themeBox?.put('theme', themeModel.toMap());
  }
}
