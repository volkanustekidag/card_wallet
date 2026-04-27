import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TextFieldCard extends StatefulWidget {
  final TextEditingController? controller;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final TextInputType? textInputType;
  final IconData? iconData;
  final String? hintText;
  final String label;
  final bool readOnly;
  final String? helperText;
  final TextStyle? textStyle;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final bool emphasize;
  final FocusNode? focusNode;

  const TextFieldCard({
    Key? key,
    this.controller,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
    this.textInputType,
    this.iconData,
    this.hintText,
    required this.label,
    this.readOnly = false,
    this.helperText,
    this.textStyle,
    this.onTap,
    this.suffixIcon,
    this.emphasize = false,
    this.focusNode,
  }) : super(key: key);

  @override
  State<TextFieldCard> createState() => _TextFieldCardState();
}

class _TextFieldCardState extends State<TextFieldCard> {
  FocusNode? _internalFocusNode;
  bool _isFocused = false;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }
    _effectiveFocusNode.addListener(_handleFocusChange);
    _isFocused = _effectiveFocusNode.hasFocus;
  }

  @override
  void didUpdateWidget(TextFieldCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode)
          ?.removeListener(_handleFocusChange);
      if (oldWidget.focusNode == null && widget.focusNode != null) {
        _internalFocusNode?..dispose();
        _internalFocusNode = null;
      } else if (widget.focusNode == null && oldWidget.focusNode != null) {
        _internalFocusNode = FocusNode();
      }
      _effectiveFocusNode.addListener(_handleFocusChange);
      _isFocused = _effectiveFocusNode.hasFocus;
    }
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _effectiveFocusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final fillColor = theme.colorScheme.surfaceContainerHighest
        .withValues(alpha: widget.emphasize ? 0.55 : 0.45);
    final labelColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8);
    final iconColor = _isFocused ? accent : theme.colorScheme.onSurfaceVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, _isFocused ? -1.5 : 0, 0),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(widget.emphasize ? 20 : 18),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _effectiveFocusNode,
        maxLength: widget.maxLength,
        keyboardType: widget.textInputType,
        readOnly: widget.readOnly,
        onTap: widget.onTap,
        style: widget.textStyle ??
            TextStyle(fontFamily: 'Poppins', 
              fontSize: widget.emphasize ? 16 : 15,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
        onChanged: widget.onChanged,
        inputFormatters: widget.inputFormatters,
        decoration: InputDecoration(
          isDense: true,
          counterText: widget.maxLength != null ? "" : null,
          labelText: widget.label,
          labelStyle: TextStyle(fontFamily: 'Poppins', 
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
          hintText: widget.hintText,
          hintStyle: TextStyle(fontFamily: 'Poppins', 
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          helperText: widget.helperText,
          helperStyle: TextStyle(fontFamily: 'Poppins', 
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          prefixIcon: widget.iconData != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 12, right: 4),
                  child: Icon(
                    widget.iconData,
                    size: 18,
                    color: iconColor,
                  ),
                )
              : null,
          prefixIconConstraints:
              const BoxConstraints(minWidth: 36, minHeight: 36),
          suffixIcon: widget.suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
          ),
        ),
      ),
    );
  }
}
