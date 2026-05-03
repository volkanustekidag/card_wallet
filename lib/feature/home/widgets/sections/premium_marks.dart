import 'package:flutter/material.dart';

/// Refined gold-fill diamond used as the premium mark across upsell
/// surfaces. CustomPainter rather than an icon font so it reads as a
/// crafted brand mark (gradient + highlight stroke) instead of a generic
/// material chip.
class GoldDiamondMark extends StatelessWidget {
  final double size;
  const GoldDiamondMark({Key? key, this.size = 14}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _DiamondPainter()),
    );
  }
}

class _DiamondPainter extends CustomPainter {
  const _DiamondPainter();

  static const _light = Color(0xFFE9D59B);
  static const _dark = Color(0xFFB8862C);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(0, size.height / 2)
      ..close();

    final fill = Paint()
      ..shader = const LinearGradient(
        colors: [_light, _dark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, fill);

    // Crisp top-right facet highlight — sells the "polished gem" look.
    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width / 2, 1),
      Offset(size.width - 1, size.height / 2),
      highlight,
    );
  }

  @override
  bool shouldRepaint(covariant _DiamondPainter oldDelegate) => false;
}

/// Outlined shield used for the biometric suggestion. Same drawing
/// philosophy as the diamond mark — geometric, no fill icon — so the two
/// upsell cards feel like one design system.
class ShieldOutlineMark extends StatelessWidget {
  final double size;
  final Color color;
  const ShieldOutlineMark({
    Key? key,
    this.size = 14,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ShieldPainter(color: color)),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  final Color color;
  const _ShieldPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w, h * 0.22)
      ..lineTo(w, h * 0.55)
      ..quadraticBezierTo(w, h, w / 2, h)
      ..quadraticBezierTo(0, h, 0, h * 0.55)
      ..lineTo(0, h * 0.22)
      ..close();

    final stroke = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _ShieldPainter oldDelegate) =>
      oldDelegate.color != color;
}
