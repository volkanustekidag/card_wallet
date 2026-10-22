import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

/// Filled input with a floating label inside the field and a soft focus
/// ring (accent hairline + 4px accent halo) — no old-style outline box.
class CwField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String label;
  final String? hint;
  final String? helper;
  final String? error;
  final bool mono;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;
  final CwIcons? icon;
  final bool autofocus;
  final bool obscure;
  final Iterable<String>? autofillHints;

  const CwField({
    super.key,
    this.controller,
    this.focusNode,
    required this.label,
    this.hint,
    this.helper,
    this.error,
    this.mono = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.trailing,
    this.icon,
    this.autofocus = false,
    this.obscure = false,
    this.autofillHints,
  });

  @override
  State<CwField> createState() => _CwFieldState();
}

class _CwFieldState extends State<CwField> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() {
    if (mounted && _focus.hasFocus != _focused) {
      setState(() => _focused = _focus.hasFocus);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final hasError = widget.error != null && widget.error!.isNotEmpty;
    final ring = hasError ? c.danger : c.accent;
    final textStyle = widget.mono
        ? CwType.mono(size: 16.5, color: c.ink, letterSpacing: 1.0)
        : CwType.body.copyWith(color: c.ink, fontSize: 16.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: CwMotion.fast,
          curve: CwMotion.standard,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(CwRadius.m),
            border: Border.all(
              color: _focused || hasError ? ring : Colors.transparent,
              width: 1.4,
            ),
            boxShadow: [
              if (_focused || hasError)
                BoxShadow(
                  color: ring.withValues(alpha: 0.14),
                  blurRadius: 0,
                  spreadRadius: 4,
                )
              else
                ...CwElevation.e1(context),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          child: Row(
            crossAxisAlignment: widget.maxLines > 1
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Padding(
                  padding: EdgeInsets.only(top: widget.maxLines > 1 ? 10 : 0),
                  child: CwIcon(widget.icon!,
                      size: CwIconSize.m,
                      color: _focused ? c.accent : c.mute),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  autofocus: widget.autofocus,
                  obscureText: widget.obscure,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  textCapitalization: widget.textCapitalization,
                  inputFormatters: widget.inputFormatters,
                  maxLength: widget.maxLength,
                  maxLines: widget.maxLines,
                  minLines: widget.maxLines > 1 ? widget.maxLines : 1,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  autofillHints: widget.autofillHints,
                  style: textStyle,
                  cursorColor: c.accent,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    counterText: '',
                    labelText: widget.label,
                    hintText: widget.hint,
                    labelStyle: CwType.callout.copyWith(color: c.mute),
                    floatingLabelStyle: CwType.caption.copyWith(
                      color: hasError ? c.danger : c.accent,
                    ),
                    hintStyle: CwType.body.copyWith(color: c.mute),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
        if (hasError || (widget.helper != null && widget.helper!.isNotEmpty))
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
            child: Text(
              hasError ? widget.error! : widget.helper!,
              style: CwType.footnote
                  .copyWith(color: hasError ? c.danger : c.mute),
            ),
          ),
      ],
    );
  }
}
