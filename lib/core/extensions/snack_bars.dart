import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/styles/app_themes.dart';

extension SnackBars on BuildContext {
  /// Generic helper. Falls back to the theme's [SnackBarThemeData] for shape,
  /// behavior and text style when [color] is null.
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBarInfo(
      BuildContext context, Color? color, String content) {
    return _showStyled(context, content, background: color);
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
      showSuccessSnackBar(String message) {
    return _showStyled(this, message, background: AppThemes.success(this));
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
      showErrorSnackBar(String message) {
    return _showStyled(this, message,
        background: Theme.of(this).colorScheme.error);
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
      showInfoSnackBar(String message) {
    return _showStyled(this, message, background: AppThemes.info(this));
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
      showWarningSnackBar(String message) {
    return _showStyled(this, message, background: AppThemes.warning(this));
  }
}

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> _showStyled(
  BuildContext context,
  String message, {
  Color? background,
}) {
  final snackTheme = Theme.of(context).snackBarTheme;
  final bg = background ?? snackTheme.backgroundColor;
  final foreground = bg == null
      ? (snackTheme.contentTextStyle?.color ?? Colors.white)
      : ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
          ? Colors.white
          : Colors.black87;
  final baseStyle =
      snackTheme.contentTextStyle ?? const TextStyle(fontSize: 14);

  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: bg,
      duration: const Duration(seconds: 2),
      content: Text(
        message.tr(),
        style: baseStyle.copyWith(color: foreground),
      ),
    ),
  );
}
