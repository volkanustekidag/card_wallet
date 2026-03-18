import 'package:flutter/material.dart';

class BackgroundShapesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = Colors.blue.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    final paint2 = Paint()
      ..color = const Color.fromARGB(255, 39, 64, 176).withOpacity(0.04)
      ..style = PaintingStyle.fill;
    final paint3 = Paint()
      ..color = const Color.fromARGB(255, 48, 76, 216).withOpacity(0.05)
      ..style = PaintingStyle.fill;
    final paint4 = Paint()
      ..color = const Color(0xFF0C1118).withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Top left circle
    canvas.drawCircle(
      Offset(-size.width * 0.2, size.height * 0.1),
      size.width * 0.5,
      paint1,
    );

    // Bottom right circle
    canvas.drawCircle(
      Offset(size.width * 1.1, size.height * 1.1),
      size.width * 0.7,
      paint2,
    );

    // Small top right circle (light)
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.08),
      size.width * 0.13,
      paint3,
    );

    // Small bottom left circle (dark)
    canvas.drawCircle(
      Offset(size.width * 0.05, size.height * 0.85),
      size.width * 0.09,
      paint4,
    );

    // Small center circle (light)
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.07,
      paint3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
