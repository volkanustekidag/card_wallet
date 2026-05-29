import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows a modern destructive confirmation as a bottom sheet — replaces the
/// previous AlertDialog flow. Returns `true` if the user confirms, `false`
/// otherwise. The optional [onConfirm] callback runs after a confirm tap
/// while the sheet is still on screen, mirroring the old `CustomDialog`
/// `onConfirm` semantics so callers don't need to change their fire-and-forget
/// shape.
///
/// All visible strings are passed already translated by the caller — the
/// helper does not call `.tr()` internally, mirroring the pattern most
/// existing call sites already follow.
Future<bool> showConfirmActionSheet({
  required BuildContext context,
  required String title,
  String? content,
  String? confirmText,
  String? cancelText,
  bool destructive = true,
  IconData? icon,
  Future<void> Function()? onConfirm,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => _ConfirmSheet(
      title: title,
      content: content,
      confirmText: confirmText ?? 'yes'.tr(),
      cancelText: cancelText ?? 'cancel'.tr(),
      destructive: destructive,
      icon: icon,
      onConfirm: onConfirm,
    ),
  );
  return result ?? false;
}

class _ConfirmSheet extends StatefulWidget {
  final String title;
  final String? content;
  final String confirmText;
  final String cancelText;
  final bool destructive;
  final IconData? icon;
  final Future<void> Function()? onConfirm;

  const _ConfirmSheet({
    required this.title,
    required this.content,
    required this.confirmText,
    required this.cancelText,
    required this.destructive,
    required this.icon,
    required this.onConfirm,
  });

  @override
  State<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<_ConfirmSheet> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = widget.destructive ? colorScheme.error : colorScheme.primary;
    final onAccent =
        widget.destructive ? colorScheme.onError : colorScheme.onPrimary;
    final iconData = widget.icon ??
        (widget.destructive
            ? Icons.delete_forever_rounded
            : Icons.help_outline_rounded);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: accent, size: 28),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            if (widget.content != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.content!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : () => _handleConfirm(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: onAccent,
                  disabledBackgroundColor: accent.withValues(alpha: 0.5),
                  disabledForegroundColor: onAccent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _busy
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(onAccent),
                        ),
                      )
                    : Text(
                        widget.confirmText,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed:
                    _busy ? null : () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurface.withValues(alpha: 0.7),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  widget.cancelText,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleConfirm(BuildContext context) async {
    HapticFeedback.heavyImpact();
    if (widget.onConfirm == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.onConfirm!();
    } finally {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }
}
