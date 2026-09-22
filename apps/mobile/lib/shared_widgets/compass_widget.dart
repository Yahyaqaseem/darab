import 'package:flutter/material.dart';

class CompassWidget extends StatelessWidget {
  final double heading;
  final VoidCallback? onTap;

  const CompassWidget({
    super.key,
    this.heading = 0.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Transform.rotate(
            angle: -heading * (3.141592653589793 / 180),
            child: CustomPaint(
              size: const Size(22, 22),
              painter: _CompassNeedlePainter(),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompassNeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // North needle (Red)
    final northPath = Path()
      ..moveTo(cx, 2)
      ..lineTo(cx + 4.5, cy)
      ..lineTo(cx - 4.5, cy)
      ..close();

    final northPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;

    canvas.drawPath(northPath, northPaint);

    // South needle (White / Light gray)
    final southPath = Path()
      ..moveTo(cx, h - 2)
      ..lineTo(cx + 4.5, cy)
      ..lineTo(cx - 4.5, cy)
      ..close();

    final southPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawPath(southPath, southPaint);

    // Center pivot dot
    canvas.drawCircle(Offset(cx, cy), 2.5, Paint()..color = const Color(0xFF0F172A));
    canvas.drawCircle(Offset(cx, cy), 1.2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
