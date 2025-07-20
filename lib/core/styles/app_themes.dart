import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppThemes {
  // Modern Color Palette
  static const Color lightPrimary = Color(0xFF2563EB);
  static const Color lightSecondary = Color(0xFF10B981);
  static const Color lightTertiary = Color(0xFF8B5CF6);
  static const Color lightError = Color(0xFFEF4444);
  static const Color lightWarning = Color(0xFFF59E0B);
  static const Color lightSuccess = Color(0xFF22C55E);
  static const Color lightInfo = Color(0xFF06B6D4);

  static const Color darkPrimary = Color(0xFF3B82F6);
  static const Color darkSecondary = Color(0xFF34D399);
  static const Color darkTertiary = Color(0xFFA78BFA);
  static const Color darkError = Color(0xFFF87171);
  static const Color darkWarning = Color(0xFFFBBF24);
  static const Color darkSuccess = Color(0xFF4ADE80);
  static const Color darkInfo = Color(0xFF22D3EE);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: lightPrimary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFDBEAFE),
      onPrimaryContainer: Color(0xFF1E3A8A),
      secondary: lightSecondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFD1FAE5),
      onSecondaryContainer: Color(0xFF065F46),
      tertiary: lightTertiary,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFEDE9FE),
      onTertiaryContainer: Color(0xFF581C87),
      error: lightError,
      onError: Colors.white,
      errorContainer: Color(0xFFFEE2E2),
      onErrorContainer: Color(0xFF991B1B),
      surface: Colors.white,
      onSurface: Color(0xFF374151),
      surfaceContainerHighest: Color(0xFFF3F4F6),
      onSurfaceVariant: Color(0xFF6B7280),
      outline: Color(0xFFD1D5DB),
      outlineVariant: Color(0xFFE5E7EB),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF111827),
      onInverseSurface: Color(0xFFF9FAFB),
      inversePrimary: Color(0xFF93C5FD),
    ),

    // Scaffold
    scaffoldBackgroundColor: const Color(0xFFF6F7FC),
    canvasColor: Colors.white,

    // App Bar Theme
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: Color(0XFFE8E8E8),
      foregroundColor: Color(0xFF1F2937),
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1F2937),
        letterSpacing: 0.5,
      ),
      iconTheme: IconThemeData(
        color: Color(0xFF374151),
        size: 24,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    ),

    // Card Theme
    cardTheme: CardTheme(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      surfaceTintColor: Colors.white,
      color: Colors.white,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: lightPrimary,
        foregroundColor: Colors.white,
        shadowColor: lightPrimary.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: lightPrimary,
        side: const BorderSide(color: lightPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: lightPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: lightPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: lightPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: lightError),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      labelStyle: const TextStyle(color: Color(0xFF6B7280)),
    ),

    // Text Theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
      displayMedium: TextStyle(
          fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
      displaySmall: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
      headlineLarge: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
      headlineMedium: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
      headlineSmall: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
      titleLarge: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1F2937)),
      titleMedium: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
      titleSmall: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
      bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Color(0xFF374151)),
      bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Color(0xFF374151)),
      bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: Color(0xFF6B7280)),
      labelLarge: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
      labelMedium: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
      labelSmall: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF)),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: lightPrimary,
      unselectedItemColor: Color(0xFF9CA3AF),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // Tab Bar Theme
    tabBarTheme: const TabBarTheme(
      labelColor: lightPrimary,
      unselectedLabelColor: Color(0xFF6B7280),
      indicatorColor: lightPrimary,
      indicatorSize: TabBarIndicatorSize.tab,
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF3F4F6),
      selectedColor: lightPrimary.withOpacity(0.2),
      disabledColor: const Color(0xFFE5E7EB),
      labelStyle: const TextStyle(color: Color(0xFF374151)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: lightPrimary,
      foregroundColor: Colors.white,
      elevation: 4,
      focusElevation: 6,
      hoverElevation: 8,
    ),

    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return lightPrimary;
        return const Color(0xFFE5E7EB);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected))
          return lightPrimary.withOpacity(0.5);
        return const Color(0xFFD1D5DB);
      }),
    ),

    // Slider Theme
    sliderTheme: SliderThemeData(
      activeTrackColor: lightPrimary,
      inactiveTrackColor: lightPrimary.withOpacity(0.3),
      thumbColor: lightPrimary,
      overlayColor: lightPrimary.withOpacity(0.2),
    ),

    // Progress Indicator Theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: lightPrimary,
      linearTrackColor: Color(0xFFE5E7EB),
      circularTrackColor: Color(0xFFE5E7EB),
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE5E7EB),
      thickness: 1,
      space: 1,
    ),

    // List Tile Theme
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // Color Scheme
    colorScheme: const ColorScheme.dark(
      primary: darkPrimary,
      onPrimary: Color(0xFF1E293B),
      primaryContainer: Color(0xFF1E40AF),
      onPrimaryContainer: Color(0xFFDBEAFE),
      secondary: darkSecondary,
      onSecondary: Color(0xFF1E293B),
      secondaryContainer: Color(0xFF047857),
      onSecondaryContainer: Color(0xFFD1FAE5),
      tertiary: darkTertiary,
      onTertiary: Color(0xFF1E293B),
      tertiaryContainer: Color(0xFF7C3AED),
      onTertiaryContainer: Color(0xFFEDE9FE),
      error: darkError,
      onError: Color(0xFF1E293B),
      errorContainer: Color(0xFFDC2626),
      onErrorContainer: Color(0xFFFEE2E2),
      surface: Color(0xFF1E293B),
      onSurface: Color(0xFFE2E8F0),
      surfaceContainerHighest: Color(0xFF334155),
      onSurfaceVariant: Color(0xFF94A3B8),
      outline: Color(0xFF475569),
      outlineVariant: Color(0xFF374151),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFF1F5F9),
      onInverseSurface: Color(0xFF1E293B),
      inversePrimary: Color(0xFF2563EB),
    ),

    // Scaffold
    scaffoldBackgroundColor: const Color(0xFF0C1118),
    canvasColor: const Color(0xFF1E293B),

    // App Bar Theme
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: Color(0xFF0F172A),
      foregroundColor: Color(0xFFF1F5F9),
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF1F5F9),
        letterSpacing: 0.5,
      ),
      iconTheme: IconThemeData(
        color: Color(0xFFE2E8F0),
        size: 24,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),

    // Card Theme
    cardTheme: CardTheme(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.3),
      surfaceTintColor: const Color(0xFF1E293B),
      color: const Color(0xFF1E293B),
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: darkPrimary,
        foregroundColor: const Color(0xFF1E293B),
        shadowColor: darkPrimary.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: darkPrimary,
        side: const BorderSide(color: darkPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: darkPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: darkPrimary,
        foregroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF475569)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF475569)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkError),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: Color(0xFF64748B)),
      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
    ),

    // Text Theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFF8FAFC)),
      displayMedium: TextStyle(
          fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFF8FAFC)),
      displaySmall: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFFF8FAFC)),
      headlineLarge: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFFF1F5F9)),
      headlineMedium: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFF1F5F9)),
      headlineSmall: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFF1F5F9)),
      titleLarge: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFFF1F5F9)),
      titleMedium: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFE2E8F0)),
      titleSmall: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFFE2E8F0)),
      bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Color(0xFFE2E8F0)),
      bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Color(0xFFE2E8F0)),
      bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: Color(0xFF94A3B8)),
      labelLarge: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFE2E8F0)),
      labelMedium: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
      labelSmall: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E293B),
      selectedItemColor: darkPrimary,
      unselectedItemColor: Color(0xFF64748B),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // Tab Bar Theme
    tabBarTheme: const TabBarTheme(
      labelColor: darkPrimary,
      unselectedLabelColor: Color(0xFF94A3B8),
      indicatorColor: darkPrimary,
      indicatorSize: TabBarIndicatorSize.tab,
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF334155),
      selectedColor: darkPrimary.withOpacity(0.2),
      disabledColor: const Color(0xFF475569),
      labelStyle: const TextStyle(color: Color(0xFFE2E8F0)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: darkPrimary,
      foregroundColor: Color(0xFF1E293B),
      elevation: 4,
      focusElevation: 6,
      hoverElevation: 8,
    ),

    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return darkPrimary;
        return const Color(0xFF475569);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected))
          return darkPrimary.withOpacity(0.5);
        return const Color(0xFF334155);
      }),
    ),

    // Slider Theme
    sliderTheme: SliderThemeData(
      activeTrackColor: darkPrimary,
      inactiveTrackColor: darkPrimary.withOpacity(0.3),
      thumbColor: darkPrimary,
      overlayColor: darkPrimary.withOpacity(0.2),
    ),

    // Progress Indicator Theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: darkPrimary,
      linearTrackColor: Color(0xFF475569),
      circularTrackColor: Color(0xFF475569),
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: Color(0xFF475569),
      thickness: 1,
      space: 1,
    ),

    // List Tile Theme
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
  );
}
