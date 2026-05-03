import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomDialog extends StatelessWidget {
  const CustomDialog({
    Key? key,
    this.onConfirm,
    this.title = "areUSure",
    this.cancelText = "cancel",
    this.content,
    this.confirmText = "yes",
    this.destructive = true,
  }) : super(key: key);

  final Function? onConfirm;
  final String title;
  final String cancelText;
  final String? content;
  final String confirmText;

  /// Whether the confirm button is destructive (uses error color). Default
  /// is true because the dialog is most often used to confirm deletes.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dialogTheme = Theme.of(context).dialogTheme;
    final accent = destructive ? colorScheme.error : colorScheme.primary;
    final onAccent =
        destructive ? colorScheme.onError : colorScheme.onPrimary;

    return AlertDialog(
      title: Text(
        title.tr(),
        style: dialogTheme.titleTextStyle,
      ),
      content: content != null
          ? Text(
              content!.tr(),
              style: dialogTheme.contentTextStyle,
            )
          : null,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            cancelText.tr(),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            HapticFeedback.heavyImpact();
            if (onConfirm != null) {
              onConfirm!();
            }
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: onAccent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            confirmText.tr(),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
