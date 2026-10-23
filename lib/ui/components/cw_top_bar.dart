import 'dart:math' as math;
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    show OverScrollHeaderStretchConfiguration;
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

/// Height of the bar row (buttons, collapsed title) under the status bar.
const double kCwBarRow = 50;

/// Line the large title sits on, under the bar row, when not [inline].
const double _kLargeLine = 50;

/// Scroll distance over which an [inline] title shrinks.
const double _kInlineCollapse = 40;

/// Pinned top bar whose large title shrinks into the bar as the page
/// scrolls: the iOS large title / Material large top app bar motion.
///
/// [inline]: the title shares the row with [actions] and just shrinks in
/// place (Home). Otherwise it sits on its own line under [leading] and
/// slides up into the middle of the bar (Settings). Once content runs under
/// the bar, the bar turns frosted and a hairline fades in. Pulling down
/// past the top grows the title a little.
///
/// Must be the first sliver of a [CustomScrollView]; it pads for the status
/// bar itself.
class CwLargeTitleBar extends StatelessWidget {
  final String title;
  final Widget? leading;
  final List<Widget> actions;
  final bool inline;

  /// Size of the title at rest; defaults to [CwType.display]'s.
  final double? titleSize;

  const CwLargeTitleBar({
    super.key,
    required this.title,
    this.leading,
    this.actions = const [],
    this.inline = false,
    this.titleSize,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _LargeTitleDelegate(
        title: title,
        leading: leading,
        actions: actions,
        inline: inline,
        titleSize: titleSize ?? CwType.display.fontSize!,
        top: MediaQuery.paddingOf(context).top,
        colors: CwColors.of(context),
        textScaler: MediaQuery.textScalerOf(context)
            .clamp(minScaleFactor: 1, maxScaleFactor: 1.15),
        textDirection: Directionality.of(context),
      ),
    );
  }
}

class _LargeTitleDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final Widget? leading;
  final List<Widget> actions;
  final bool inline;
  final double titleSize;
  final double top;
  final CwColors colors;
  final TextScaler textScaler;
  final TextDirection textDirection;

  _LargeTitleDelegate({
    required this.title,
    required this.leading,
    required this.actions,
    required this.inline,
    required this.titleSize,
    required this.top,
    required this.colors,
    required this.textScaler,
    required this.textDirection,
  });

  @override
  double get minExtent => top + kCwBarRow;

  @override
  double get maxExtent => minExtent + (inline ? 0 : _kLargeLine);

  double get _collapse => inline ? _kInlineCollapse : _kLargeLine;

  /// Collapsed size of the title.
  double get _smallSize => inline ? 22 : 17;

  @override
  OverScrollHeaderStretchConfiguration get stretchConfiguration =>
      OverScrollHeaderStretchConfiguration();

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return LayoutBuilder(builder: (context, box) {
      final width = box.maxWidth;
      final stretch = math.max(0.0, box.maxHeight - maxExtent);
      final t = (shrinkOffset / _collapse).clamp(0.0, 1.0);
      // How far content has run under the bar: frosts it and shows the line.
      final under =
          ((shrinkOffset - (maxExtent - minExtent)) / 14).clamp(0.0, 1.0);

      final style =
          CwType.display.copyWith(color: colors.ink, fontSize: titleSize);
      final actionsWidth =
          actions.isEmpty ? 0.0 : actions.length * 48.0 - 10 + 18;
      final maxTitle = inline ? width - 22 - actionsWidth - 8 : width - 44;
      final painter = TextPainter(
        text: TextSpan(text: title, style: style),
        textScaler: textScaler,
        textDirection: textDirection,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: math.max(0, maxTitle));
      final titleWidth = painter.width;
      final titleHeight = painter.height;
      painter.dispose();

      final small = _smallSize / titleSize;
      final grow = 1 + math.min(stretch / 500, 0.1);
      final scale = lerpDouble(1, small, t)! * grow;
      final restX = 22.0;
      final endX = inline ? restX : (width - titleWidth * small) / 2;
      final restY = inline
          ? top + kCwBarRow / 2
          : top + kCwBarRow + _kLargeLine / 2 - 4 + stretch;
      final endY = top + kCwBarRow / 2;
      final x = lerpDouble(restX, endX, t)!;
      final y = lerpDouble(restY, endY, t)!;

      final bg = colors.bg.withValues(alpha: 1 - 0.14 * under);
      return Stack(
        fit: StackFit.expand,
        children: [
          if (under > 0)
            ClipRect(
              child: BackdropFilter(
                filter:
                    ImageFilter.blur(sigmaX: 18 * under, sigmaY: 18 * under),
                child: ColoredBox(color: bg),
              ),
            )
          else
            ColoredBox(color: bg),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 0.5,
            child: ColoredBox(
                color: colors.line.withValues(alpha: colors.line.a * under)),
          ),
          Positioned(
            left: x,
            top: y - titleHeight / 2,
            width: titleWidth + 1,
            height: titleHeight,
            child: Transform.scale(
              scale: scale,
              alignment: AlignmentDirectional.centerStart,
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  textScaler: textScaler,
                  style: style,
                ),
              ),
            ),
          ),
          Positioned(
            top: top,
            left: 14,
            right: 18,
            height: kCwBarRow,
            child: Row(
              children: [
                if (leading != null) leading!,
                const Spacer(),
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  actions[i],
                ],
              ],
            ),
          ),
        ],
      );
    });
  }

  @override
  bool shouldRebuild(_LargeTitleDelegate old) =>
      old.title != title ||
      old.leading != leading ||
      old.actions != actions ||
      old.inline != inline ||
      old.titleSize != titleSize ||
      old.top != top ||
      old.colors != colors ||
      old.textScaler != textScaler ||
      old.textDirection != textDirection;
}

/// A fixed top bar over a scrolling body. A hairline fades in under the bar
/// once the body scrolls beneath it, matching a collapsed [CwLargeTitleBar].
class CwScrollEdge extends StatefulWidget {
  final Widget bar;
  final Widget body;

  const CwScrollEdge({super.key, required this.bar, required this.body});

  @override
  State<CwScrollEdge> createState() => _CwScrollEdgeState();
}

class _CwScrollEdgeState extends State<CwScrollEdge> {
  final _scrolled = ValueNotifier(false);

  @override
  void dispose() {
    _scrolled.dispose();
    super.dispose();
  }

  bool _onNotification(Notification n) {
    final metrics = switch (n) {
      ScrollNotification(:final metrics, :final depth) when depth == 0 =>
        metrics,
      ScrollMetricsNotification(:final metrics, :final depth) when depth == 0 =>
        metrics,
      _ => null,
    };
    if (metrics != null && metrics.axis == Axis.vertical) {
      _scrolled.value = metrics.pixels > metrics.minScrollExtent + 0.5;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return Column(
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: _scrolled,
          builder: (context, scrolled, bar) => AnimatedContainer(
            duration: CwMotion.base,
            curve: CwMotion.standard,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  width: 0.5,
                  color: scrolled ? c.line : c.line.withValues(alpha: 0),
                ),
              ),
            ),
            child: bar,
          ),
          child: widget.bar,
        ),
        Expanded(
          child: NotificationListener<Notification>(
            onNotification: _onNotification,
            child: widget.body,
          ),
        ),
      ],
    );
  }
}
