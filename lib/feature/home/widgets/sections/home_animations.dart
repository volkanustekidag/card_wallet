import 'package:flutter/material.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';

/// One-shot fade + slide-up entrance. Triggers in [initState] after [delay],
/// runs for [duration], then stays settled. Designed for staggering home
/// sections without dragging in an external animation package.
class FadeSlideIn extends StatefulWidget {
  final Duration delay;
  final Duration duration;
  final double offsetY;
  final Widget child;

  const FadeSlideIn({
    Key? key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 520),
    this.offsetY = 36,
  }) : super(key: key);

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _curved =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  late final Animation<double> _slideCurve = CurvedAnimation(
    parent: _controller,
    curve: const Cubic(0.16, 1.0, 0.3, 1.05),
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final fade = _curved.value.clamp(0.0, 1.0);
        final slide = _slideCurve.value;
        return Opacity(
          opacity: fade,
          child: Transform.translate(
            offset: Offset(0, widget.offsetY * (1 - slide)),
            child: child,
          ),
        );
      },
    );
  }
}

/// Tap-feedback wrapper. Scales the [child] down to [scale] on press and
/// back to 1 on release/cancel. When [onTap] is null the gesture is inert.
class PressScale extends StatefulWidget {
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;
  final Widget child;
  final HitTestBehavior behavior;

  const PressScale({
    Key? key,
    required this.child,
    this.onTap,
    this.scale = 0.96,
    this.duration = kFastAnim,
    this.behavior = HitTestBehavior.opaque,
  }) : super(key: key);

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool down) {
    if (widget.onTap == null) return;
    if (_down == down) return;
    setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Plays a one-shot expanding ring of [color] each time the user taps.
/// Wrap any tappable region; the burst is painted on top of [child] without
/// stealing the tap. The ring fades out as it grows so it never feels heavy.
class RippleBurst extends StatefulWidget {
  final Widget child;
  final Color color;
  final Duration duration;
  final double maxRadius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const RippleBurst({
    Key? key,
    required this.child,
    required this.color,
    this.duration = const Duration(milliseconds: 420),
    this.maxRadius = 120,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  State<RippleBurst> createState() => _RippleBurstState();
}

class _RippleBurstState extends State<RippleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);
  Offset? _origin;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fire(Offset local) {
    setState(() => _origin = local);
    _controller
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) => _fire(d.localPosition),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  if (_origin == null || _controller.value == 0) {
                    return const SizedBox.shrink();
                  }
                  return CustomPaint(
                    painter: _BurstPainter(
                      origin: _origin!,
                      progress: _controller.value,
                      color: widget.color,
                      maxRadius: widget.maxRadius,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  final Offset origin;
  final double progress;
  final Color color;
  final double maxRadius;

  _BurstPainter({
    required this.origin,
    required this.progress,
    required this.color,
    required this.maxRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOutCubic.transform(progress);
    final radius = maxRadius * t;
    final alpha = (1 - t) * 0.45;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * (1 - t * 0.6)
      ..color = color.withValues(alpha: alpha);
    canvas.drawCircle(origin, radius, paint);

    final fillPaint = Paint()
      ..color = color.withValues(alpha: alpha * 0.35);
    canvas.drawCircle(origin, radius * 0.92, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.origin != origin;
}

/// Nudges the wrapped icon to the right and back when [trigger] flips.
/// Used to hint navigation direction when a row is tapped — chevron pops
/// 4 px right, then settles.
class ChevronNudge extends StatefulWidget {
  final Widget child;
  final Object trigger;
  final double distance;

  const ChevronNudge({
    Key? key,
    required this.child,
    required this.trigger,
    this.distance = 4,
  }) : super(key: key);

  @override
  State<ChevronNudge> createState() => _ChevronNudgeState();
}

class _ChevronNudgeState extends State<ChevronNudge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  @override
  void didUpdateWidget(covariant ChevronNudge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        // 0..1 ease-out outward, then back via sine.
        final v = _controller.value;
        final offset = widget.distance *
            (v == 0 ? 0 : (1 - (2 * v - 1).abs())) *
            Curves.easeOut.transform(v < 0.5 ? v * 2 : (1 - v) * 2);
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
    );
  }
}

/// Long-press "peek": scales [child] up to [peekScale] while held, with a
/// dim overlay. Releases back to 1.0. If [onPeekRelease] is set, it fires
/// when the press is released after the threshold.
class LongPressPeek extends StatefulWidget {
  final Widget child;
  final double peekScale;
  final Duration peekIn;
  final Duration peekOut;
  final VoidCallback? onPeekStart;
  final VoidCallback? onPeekRelease;

  const LongPressPeek({
    Key? key,
    required this.child,
    this.peekScale = 1.08,
    this.peekIn = const Duration(milliseconds: 220),
    this.peekOut = const Duration(milliseconds: 180),
    this.onPeekStart,
    this.onPeekRelease,
  }) : super(key: key);

  @override
  State<LongPressPeek> createState() => _LongPressPeekState();
}

class _LongPressPeekState extends State<LongPressPeek> {
  bool _peeking = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (_) {
        widget.onPeekStart?.call();
        setState(() => _peeking = true);
      },
      onLongPressEnd: (_) {
        if (_peeking) widget.onPeekRelease?.call();
        setState(() => _peeking = false);
      },
      onLongPressCancel: () => setState(() => _peeking = false),
      child: AnimatedScale(
        scale: _peeking ? widget.peekScale : 1.0,
        duration: _peeking ? widget.peekIn : widget.peekOut,
        curve: _peeking ? Curves.easeOutBack : Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
