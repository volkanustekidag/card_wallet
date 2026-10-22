import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

/// Material themes built from the v2 design tokens ([CwColors], [CwType]).
///
/// The app uses the platform font (SF Pro / Roboto) — no custom UI font.
/// Colour lives in the cards; the chrome is neutral with one accent.
class AppThemes {
  AppThemes._();

  // Kept for call sites that need a semantic colour without a theme lookup.
  static const Color lightPrimary = Color(0xFF4B4BF0);
  static const Color darkPrimary = Color(0xFF8C8CFF);
  static const Color lightWarning = Color(0xFFDC6803);
  static const Color darkWarning = Color(0xFFFBBF24);
  static const Color lightSuccess = Color(0xFF12B76A);
  static const Color darkSuccess = Color(0xFF34D399);
  static const Color lightInfo = Color(0xFF4B4BF0);
  static const Color darkInfo = Color(0xFF8C8CFF);

  static Color success(BuildContext context) => CwColors.of(context).ok;
  static Color warning(BuildContext context) => CwColors.of(context).warn;
  static Color info(BuildContext context) => CwColors.of(context).accent;

  static ThemeData lightTheme = _build(CwColors.light, Brightness.light);
  static ThemeData darkTheme = _build(CwColors.dark, Brightness.dark);

  static ThemeData _build(CwColors c, Brightness b) {
    final isDark = b == Brightness.dark;
    final scheme = ColorScheme(
      brightness: b,
      primary: c.accent,
      onPrimary: Colors.white,
      secondary: c.ink,
      onSecondary: c.bg,
      tertiary: c.ok,
      onTertiary: Colors.white,
      error: c.danger,
      onError: Colors.white,
      surface: c.bg,
      onSurface: c.ink,
      onSurfaceVariant: c.mute,
      surfaceContainerLowest: c.surface,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surface2,
      surfaceContainerHighest: c.surface2,
      outline: c.line,
      outlineVariant: c.line,
      shadow: Colors.black,
      inverseSurface: c.ink,
      onInverseSurface: c.bg,
      primaryContainer: c.accentSoft,
      onPrimaryContainer: c.accent,
    );

    final text = CwType.textTheme(c.ink, c.mute);
    final overlay = isDark
        ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
        : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent);

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      dividerColor: c.line,
      iconTheme: IconThemeData(color: c.ink, size: 24),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: b,
        primaryColor: c.accent,
        scaffoldBackgroundColor: c.bg,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.ink,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: overlay,
        titleTextStyle: CwType.headline.copyWith(color: c.ink),
        iconTheme: IconThemeData(color: c.ink),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CwRadius.m),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.ink,
          foregroundColor: c.bg,
          minimumSize: const Size.fromHeight(54),
          textStyle: CwType.headline,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CwRadius.m + 2),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.ink,
          foregroundColor: c.bg,
          elevation: 0,
          minimumSize: const Size(64, 48),
          textStyle: CwType.callout.copyWith(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CwRadius.m),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.ink,
          side: BorderSide(color: c.line),
          minimumSize: const Size(64, 48),
          textStyle: CwType.callout.copyWith(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CwRadius.m),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accent,
          textStyle: CwType.callout.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: CwType.callout.copyWith(color: c.mute),
        floatingLabelStyle: CwType.caption.copyWith(color: c.accent),
        hintStyle: CwType.body.copyWith(color: c.mute),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CwRadius.m),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CwRadius.m),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CwRadius.m),
          borderSide: BorderSide(color: c.accent, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CwRadius.m),
          borderSide: BorderSide(color: c.danger, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CwRadius.m),
          borderSide: BorderSide(color: c.danger, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface2,
        selectedColor: c.ink,
        labelStyle: CwType.footnote.copyWith(
          color: c.ink,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: CwType.footnote.copyWith(color: c.bg),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.ink,
        foregroundColor: c.bg,
        elevation: 6,
        shape: const CircleBorder(),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.ok : null,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.ink),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: c.ink,
        textColor: c.ink,
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.ink,
        contentTextStyle: CwType.callout.copyWith(color: c.bg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CwRadius.m),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CwRadius.l),
        ),
        titleTextStyle: CwType.headline.copyWith(color: c.ink),
        contentTextStyle: CwType.body.copyWith(color: c.ink2),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: c.surface,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(CwRadius.xl)),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
    );
  }
}
