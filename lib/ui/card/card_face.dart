import 'package:flutter/material.dart';
import 'package:wallet_app/ui/card/card_material.dart';
import 'package:wallet_app/ui/card/tilt.dart';
import 'package:wallet_app/ui/tokens.dart';

/// The physical-feeling card surface: material gradient + film grain +
/// specular highlight. Set [interactive] on the single focused card to make
/// the highlight follow the phone's tilt; lists keep it static (cheap).
class CardFace extends StatefulWidget {
  final CardMaterial material;
  final Widget? child;
  final double? height;
  final double? width;
  final double radius;
  final bool interactive;
  final bool shadow;
  final EdgeInsetsGeometry padding;

  const CardFace({
    super.key,
    required this.material,
    this.child,
    this.height,
    this.width,
    this.radius = CwRadius.card,
    this.interactive = false,
    this.shadow = true,
    this.padding = const EdgeInsets.fromLTRB(18, 16, 18, 16),
  });

  @override
  State<CardFace> createState() => _CardFaceState();
}

class _CardFaceState extends State<CardFace> with CwTiltSubscriber {
  @override
  bool get wantsTilt => widget.interactive;

  @override
  Widget build(BuildContext context) {
    final m = widget.material;
    final radius = BorderRadius.circular(widget.radius);
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: m.gradient,
        boxShadow: widget.shadow
            ? const [
                BoxShadow(
                  color: Color(0x330E0F12),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ]
            : null,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: Colors.white.withValues(alpha: m.isMetal ? 0.22 : 0.10),
          width: 0.8,
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            const Positioned.fill(child: _Grain()),
            Positioned.fill(
              child: RepaintBoundary(
                child: widget.interactive
                    ? ValueListenableBuilder<Offset>(
                        valueListenable: CwTilt.instance.value,
                        builder: (_, t, __) => _Shine(tilt: t, metal: m.isMetal),
                      )
                    : _Shine(tilt: Offset.zero, metal: m.isMetal),
              ),
            ),
            Padding(
              padding: widget.padding,
              child: DefaultTextStyle.merge(
                style: TextStyle(color: m.foreground),
                child: IconTheme.merge(
                  data: IconThemeData(color: m.foreground),
                  child: widget.child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Grain extends StatelessWidget {
  const _Grain();

  @override
  Widget build(BuildContext context) => const IgnorePointer(
        child: Image(
          image: AssetImage('assets/images/card_grain.png'),
          repeat: ImageRepeat.repeat,
          fit: BoxFit.none,
          filterQuality: FilterQuality.none,
          opacity: AlwaysStoppedAnimation(0.55),
          excludeFromSemantics: true,
        ),
      );
}

class _Shine extends StatelessWidget {
  final Offset tilt;
  final bool metal;

  const _Shine({required this.tilt, required this.metal});

  @override
  Widget build(BuildContext context) {
    final shift = tilt.dx * 0.6;
    final strength = metal ? 0.30 : 0.16;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-1.4 + shift, -1 + tilt.dy * 0.3),
            end: Alignment(1.4 + shift, 1 - tilt.dy * 0.3),
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: strength),
              Colors.white.withValues(alpha: 0),
            ],
            stops: const [0.32, 0.47, 0.62],
          ),
        ),
      ),
    );
  }
}
