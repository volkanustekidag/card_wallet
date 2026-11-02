import 'package:flutter/material.dart';
import 'package:wallet_app/ui/components/cw_button.dart';
import 'package:wallet_app/ui/components/cw_top_bar.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

/// Add / edit form page: close · title · optional action, a live preview,
/// the fields, and a primary button that stays above the keyboard.
class CwFormScaffold extends StatelessWidget {
  final String title;
  final Widget? preview;
  final List<Widget> children;
  final Widget button;
  final Widget? action;

  const CwFormScaffold({
    super.key,
    required this.title,
    required this.children,
    required this.button,
    this.preview,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return CwPageStyle(
      child: Scaffold(
        backgroundColor: c.bg,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          bottom: false,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Column(
              children: [
                Expanded(
                  child: CwScrollEdge(
                    bar: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                      child: Row(
                        children: [
                          CwCircleButton(
                            CwIcons.close,
                            onPressed: () => Navigator.of(context).maybePop(),
                            semanticLabel: MaterialLocalizations.of(context)
                                .closeButtonLabel,
                          ),
                          Expanded(
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CwType.headline.copyWith(color: c.ink),
                            ),
                          ),
                          action ?? const SizedBox(width: 38),
                        ],
                      ),
                    ),
                    body: ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(
                          CwSpace.gutter, 8, CwSpace.gutter, 24),
                      children: [
                        if (preview != null) ...[
                          preview!,
                          const SizedBox(height: 16),
                        ],
                        ...children,
                      ],
                    ),
                  ),
                ),
                Container(
                  color: c.bg,
                  padding: EdgeInsets.fromLTRB(
                      CwSpace.gutter,
                      8,
                      CwSpace.gutter,
                      12 + MediaQuery.paddingOf(context).bottom),
                  child: button,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small text action in a form header ("Scan").
class CwHeaderAction extends StatelessWidget {
  final CwIcons icon;
  final String label;
  final VoidCallback onTap;

  const CwHeaderAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return Material(
      color: c.surface,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CwIcon(icon, size: 16, color: c.accent),
              const SizedBox(width: 6),
              Text(label,
                  style: CwType.footnote
                      .copyWith(color: c.accent, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wrap of pill choices (reminder lead times etc.).
class CwChoiceChips<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  const CwChoiceChips({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values)
          GestureDetector(
            onTap: () => onSelected(v),
            child: AnimatedContainer(
              duration: CwMotion.fast,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: v == selected ? c.ink : c.surface2,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                label(v),
                style: CwType.footnote.copyWith(
                  color: v == selected ? c.bg : c.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
