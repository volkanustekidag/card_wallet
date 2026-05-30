import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wallet_app/core/styles/app_themes.dart';

/// Wallet snackbar helper. Implemented as an [OverlayEntry] on the root
/// [Overlay] (not [ScaffoldMessenger]) so the message renders above any
/// modal bottom sheet or dialog currently on screen — those live on the
/// same root overlay, and entries inserted later sit on top.
extension SnackBars on BuildContext {
  void showSnackBarInfo(BuildContext context, Color? color, String content) =>
      _showOverlaySnack(context, content, background: color);

  void showSuccessSnackBar(String message) =>
      _showOverlaySnack(this, message, background: AppThemes.success(this));

  void showErrorSnackBar(String message) => _showOverlaySnack(
        this,
        message,
        background: Theme.of(this).colorScheme.error,
      );

  void showInfoSnackBar(String message) =>
      _showOverlaySnack(this, message, background: AppThemes.info(this));

  void showWarningSnackBar(String message) =>
      _showOverlaySnack(this, message, background: AppThemes.warning(this));
}

OverlayEntry? _activeEntry;

void _showOverlaySnack(
  BuildContext context,
  String message, {
  Color? background,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  final snackTheme = Theme.of(context).snackBarTheme;
  var bg = background ??
      snackTheme.backgroundColor ??
      Theme.of(context).colorScheme.inverseSurface;
  if (background != null && bg.computeLuminance() > 0.45) {
    final hsl = HSLColor.fromColor(bg);
    bg = hsl.withLightness((hsl.lightness * 0.55).clamp(0.0, 1.0)).toColor();
  }
  final baseStyle =
      snackTheme.contentTextStyle ?? const TextStyle(fontSize: 14);

  _activeEntry?.remove();
  _activeEntry = null;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _OverlaySnack(
      message: message.tr(),
      background: bg,
      textStyle: baseStyle.copyWith(color: Colors.white),
      onDone: () {
        if (entry.mounted) entry.remove();
        if (identical(_activeEntry, entry)) _activeEntry = null;
      },
    ),
  );
  _activeEntry = entry;
  overlay.insert(entry);
}

class _OverlaySnack extends StatefulWidget {
  final String message;
  final Color background;
  final TextStyle textStyle;
  final VoidCallback onDone;

  const _OverlaySnack({
    required this.message,
    required this.background,
    required this.textStyle,
    required this.onDone,
  });

  @override
  State<_OverlaySnack> createState() => _OverlaySnackState();
}

class _OverlaySnackState extends State<_OverlaySnack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    )..forward();
    _dismissTimer = Timer(const Duration(milliseconds: 2000), _close);
  }

  Future<void> _close() async {
    if (!mounted) return;
    await _ac.reverse();
    if (!mounted) return;
    widget.onDone();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottom = mq.viewInsets.bottom + mq.padding.bottom + 16;
    final slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));
    final fade = CurvedAnimation(parent: _ac, curve: Curves.easeOut);

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottom,
      child: FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: slide,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: widget.background,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(widget.message, style: widget.textStyle),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
