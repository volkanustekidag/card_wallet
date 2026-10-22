import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wallet_app/ui/components/cw_button.dart';
import 'package:wallet_app/ui/components/cw_misc.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';
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
  CwIcons? glyph,
  Future<void> Function()? onConfirm,
}) async {
  final result = await showCwSheet<bool>(
    context,
    builder: (sheetContext) => _ConfirmSheet(
      title: title,
      content: content,
      confirmText: confirmText ?? 'yes'.tr(),
      cancelText: cancelText ?? 'cancel'.tr(),
      destructive: destructive,
      icon: icon,
      glyph: glyph,
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
  final CwIcons? glyph;
  final Future<void> Function()? onConfirm;

  const _ConfirmSheet({
    required this.title,
    required this.content,
    required this.confirmText,
    required this.cancelText,
    required this.destructive,
    required this.icon,
    this.glyph,
    required this.onConfirm,
  });

  @override
  State<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<_ConfirmSheet> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final accent = widget.destructive ? c.danger : c.accent;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: widget.destructive ? c.dangerSoft : c.accentSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: widget.icon != null
                    ? Icon(widget.icon, color: accent, size: 24)
                    : CwIcon(
                        widget.glyph ??
                            (widget.destructive ? CwIcons.trash : CwIcons.help),
                        size: CwIconSize.l,
                        color: accent,
                      ),
              ),
            ),
            const SizedBox(height: 14),
            Text(widget.title,
                textAlign: TextAlign.center,
                style: CwType.title.copyWith(color: c.ink, fontSize: 20)),
            if (widget.content != null) ...[
              const SizedBox(height: 8),
              Text(widget.content!,
                  textAlign: TextAlign.center,
                  style: CwType.callout.copyWith(color: c.ink2, height: 1.4)),
            ],
            const SizedBox(height: 22),
            CwButton(
              widget.confirmText,
              kind: widget.destructive
                  ? CwButtonKind.destructive
                  : CwButtonKind.primary,
              loading: _busy,
              onPressed: _busy ? null : () => _handleConfirm(context),
            ),
            const SizedBox(height: 6),
            CwButton.ghost(
              widget.cancelText,
              onPressed: _busy ? null : () => Navigator.of(context).pop(false),
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
