import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

/// iOS-style segmented control (used on both platforms for consistency).
class CwSegmented<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  final bool onDark;

  const CwSegmented({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final track = onDark ? Colors.white.withValues(alpha: 0.12) : c.surface2;
    final thumb = onDark ? Colors.white : c.surface;
    final onThumb = onDark ? const Color(0xFF0B0C0F) : c.ink;
    final off = onDark ? Colors.white.withValues(alpha: 0.75) : c.ink2;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(onDark ? 999 : 11),
      ),
      child: Row(
        children: [
          for (final v in values)
            Expanded(
              child: Semantics(
                selected: v == selected,
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (v == selected) return;
                    HapticFeedback.selectionClick();
                    onChanged(v);
                  },
                  child: AnimatedContainer(
                    duration: CwMotion.fast,
                    curve: CwMotion.standard,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: v == selected ? thumb : Colors.transparent,
                      borderRadius: BorderRadius.circular(onDark ? 999 : 9),
                      boxShadow: v == selected && !onDark
                          ? const [
                              BoxShadow(
                                color: Color(0x1F000000),
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label(v),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CwType.footnote.copyWith(
                        fontWeight: FontWeight.w600,
                        color: v == selected ? onThumb : off,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small rounded label (status, card type).
class CwPill extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;
  final CwIcons? icon;

  const CwPill(
    this.text, {
    super.key,
    required this.background,
    required this.foreground,
    this.icon,
  });

  factory CwPill.ok(BuildContext context, String text, {CwIcons? icon}) {
    final c = CwColors.of(context);
    return CwPill(text, background: c.okSoft, foreground: c.ok, icon: icon);
  }

  factory CwPill.warn(BuildContext context, String text, {CwIcons? icon}) {
    final c = CwColors.of(context);
    return CwPill(text, background: c.warnSoft, foreground: c.warn, icon: icon);
  }

  factory CwPill.accent(BuildContext context, String text, {CwIcons? icon}) {
    final c = CwColors.of(context);
    return CwPill(text,
        background: c.accentSoft, foreground: c.accent, icon: icon);
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              CwIcon(icon!, size: 13, color: foreground),
              const SizedBox(width: 4),
            ],
            Text(
              text,
              style: CwType.caption.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

/// Tiny centred trust line: "Encrypted on this device · never uploaded".
class CwTrustLine extends StatelessWidget {
  final String text;
  final Color? color;
  final CwIcons icon;

  const CwTrustLine(
    this.text, {
    super.key,
    this.color,
    this.icon = CwIcons.shield,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? CwColors.of(context).mute;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        CwIcon(icon, size: 14, color: c),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: CwType.caption.copyWith(color: c),
          ),
        ),
      ],
    );
  }
}

/// Inline message box: warning / success / info.
class CwNotice extends StatelessWidget {
  final String text;
  final String? title;
  final CwIcons icon;
  final Color background;
  final Color foreground;

  const CwNotice({
    super.key,
    required this.text,
    this.title,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  factory CwNotice.warn(BuildContext context, String text, {String? title}) {
    final c = CwColors.of(context);
    return CwNotice(
      text: text,
      title: title,
      icon: CwIcons.warning,
      background: c.warnSoft,
      foreground: c.warn,
    );
  }

  factory CwNotice.ok(BuildContext context, String text, {String? title}) {
    final c = CwColors.of(context);
    return CwNotice(
      text: text,
      title: title,
      icon: CwIcons.checkCircle,
      background: c.okSoft,
      foreground: c.ok,
    );
  }

  factory CwNotice.info(BuildContext context, String text, {String? title}) {
    final c = CwColors.of(context);
    return CwNotice(
      text: text,
      title: title,
      icon: CwIcons.info,
      background: c.accentSoft,
      foreground: c.accent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(CwRadius.m),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CwIcon(icon, size: CwIconSize.m, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(title!,
                      style: CwType.callout
                          .copyWith(color: c.ink, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                ],
                Text(text, style: CwType.footnote.copyWith(color: c.ink2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grab handle + rounded modal sheet with CardWallet styling.
Future<T?> showCwSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool useRootNavigator = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    useSafeArea: true,
    // Page colour, so grouped rows and fields (surface) stand out.
    backgroundColor: CwColors.of(context).bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(CwRadius.xl)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 38,
            height: 5,
            decoration: BoxDecoration(
              color: CwColors.of(ctx).surface2,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 10),
          Flexible(child: builder(ctx)),
        ],
      ),
    ),
  );
}

/// Centred empty / zero state with an icon in a soft tile.
class CwEmptyState extends StatelessWidget {
  final CwIcons icon;
  final String title;
  final String? message;
  final Widget? action;

  const CwEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(22),
              boxShadow: CwElevation.e1(context),
            ),
            alignment: Alignment.center,
            child: CwIcon(icon, size: CwIconSize.xl, color: c.ink),
          ),
          const SizedBox(height: 18),
          Text(title,
              textAlign: TextAlign.center,
              style: CwType.headline.copyWith(color: c.ink)),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(message!,
                textAlign: TextAlign.center,
                style: CwType.footnote.copyWith(color: c.mute)),
          ],
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    );
  }
}

/// One option of [showCwChoiceSheet].
class CwChoice<T> {
  final T value;
  final String label;
  final CwIcons? icon;
  const CwChoice(this.value, this.label, {this.icon});
}

/// Title + optional subtitle + a grouped list with a check on the current
/// value. Returns the picked value (null when dismissed).
Future<T?> showCwChoiceSheet<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  required List<CwChoice<T>> options,
  required T selected,
}) {
  return showCwSheet<T>(
    context,
    builder: (sheet) {
      final c = CwColors.of(sheet);
      return SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 2, 22, 4),
                child: Text(title,
                    style: CwType.title.copyWith(color: c.ink, fontSize: 20)),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 4),
                  child: Text(subtitle,
                      style: CwType.footnote.copyWith(color: c.mute)),
                ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(CwRadius.l),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < options.length; i++) ...[
                        if (i > 0)
                          Divider(
                              height: 1,
                              thickness: 1,
                              indent: 16,
                              color: c.line),
                        InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(sheet, options[i].value);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                if (options[i].icon != null) ...[
                                  CwIcon(options[i].icon!,
                                      size: CwIconSize.m, color: c.ink2),
                                  const SizedBox(width: 12),
                                ],
                                Expanded(
                                  child: Text(options[i].label,
                                      style: CwType.body
                                          .copyWith(color: c.ink)),
                                ),
                                if (options[i].value == selected)
                                  CwIcon(CwIcons.check,
                                      size: CwIconSize.m, color: c.accent),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
