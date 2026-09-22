import 'package:flutter/material.dart';

class NavCursorWidget extends StatelessWidget {
  final double bearing;
  final double size;

  const NavCursorWidget({
    super.key,
    this.bearing = 0.0,
    this.size = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: bearing * (3.141592653589793 / 180),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Soft glowing pulse aura
            Container(
              width: size * 0.9,
              height: size * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.35),
                    blurRadius: 16,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
            // 3D Navigation Chevron / Arrowhead (Waze-style)
            CustomPaint(
              size: Size(size * 0.7, size * 0.7),
              painter: _WazeArrowPainter(),
            ),
          ],
        ),
      ),
    );
  }
}

class _WazeArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Drop shadow
    final shadowPath = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.9)
      ..lineTo(w * 0.5, h * 0.65)
      ..lineTo(0, h * 0.9)
      ..close();

    canvas.drawShadow(shadowPath, Colors.black.withOpacity(0.5), 6.0, true);

    // Cyan Gradient fill
    final rect = Rect.fromLTWH(0, 0, w, h);
    final gradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF26C6DA), // Bright cyan
        Color(0xFF00ACC1), // Deep teal
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(shadowPath, paint);

    // White crisp border
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(shadowPath, borderPaint);

    // Inner bright core highlight
    final innerPath = Path()
      ..moveTo(w * 0.5, h * 0.2)
      ..lineTo(w * 0.75, h * 0.75)
      ..lineTo(w * 0.5, h * 0.6)
      ..lineTo(w * 0.25, h * 0.75)
      ..close();

    final innerPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    canvas.drawPath(innerPath, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
