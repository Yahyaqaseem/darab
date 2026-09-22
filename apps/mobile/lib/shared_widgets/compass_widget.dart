import 'dart:math' as math;
import 'package:flutter/material.dart';

/// DARB Minimal Navigation Compass
/// 
/// Features:
/// - Minimal circular design with thin outer ring
/// - Clean faceted directional needle with small red North accent
/// - Crisp 'N' cardinal indicator
/// - Rotates in real time using the device heading
class CompassWidget extends StatelessWidget {
  final double heading;
  final VoidCallback? onTap;
  final double size;

  const CompassWidget({
    super.key,
    this.heading = 0.0,
    this.onTap,
    this.size = 44.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withOpacity(0.94),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.14),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.28),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Transform.rotate(
            angle: -heading * (math.pi / 180.0),
            child: CustomPaint(
              size: Size(size * 0.72, size * 0.72),
              painter: _DarbCompassPainter(),
            ),
          ),
        ),
      ),
    );
  }
}

class _DarbCompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.5;
    final r = w * 0.46;

    // 1. Thin Outer Graduation Ring with 4 Cardinal Ticks
    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(cx, cy), r, ringPaint);

    // North tick
    canvas.drawLine(Offset(cx, cy - r), Offset(cx, cy - r + 3), Paint()..color = const Color(0xFFEF4444)..strokeWidth = 1.4);
    // South tick
    canvas.drawLine(Offset(cx, cy + r - 3), Offset(cx, cy + r), ringPaint);
    // East / West ticks
    canvas.drawLine(Offset(cx - r, cy), Offset(cx - r + 3, cy), ringPaint);
    canvas.drawLine(Offset(cx + r - 3, cy), Offset(cx + r, cy), ringPaint);

    // 2. 'N' Indicator Label
    final tp = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(
          color: Color(0xFFEF4444),
          fontSize: 7.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - r + 3.5));

    // 3. Faceted North Needle (Red Accent)
    final northLeft = Path()
      ..moveTo(cx, cy - r + 11.0)
      ..lineTo(cx - 3.2, cy)
      ..lineTo(cx, cy - 2.5)
      ..close();
    canvas.drawPath(northLeft, Paint()..color = const Color(0xFFEF4444)..style = PaintingStyle.fill);

    final northRight = Path()
      ..moveTo(cx, cy - r + 11.0)
      ..lineTo(cx, cy - 2.5)
      ..lineTo(cx + 3.2, cy)
      ..close();
    canvas.drawPath(northRight, Paint()..color = const Color(0xFFDC2626)..style = PaintingStyle.fill);

    // 4. Faceted South Needle (Slate / White)
    final southLeft = Path()
      ..moveTo(cx, cy + r - 5.0)
      ..lineTo(cx - 3.2, cy)
      ..lineTo(cx, cy + 2.5)
      ..close();
    canvas.drawPath(southLeft, Paint()..color = const Color(0xFF64748B)..style = PaintingStyle.fill);

    final southRight = Path()
      ..moveTo(cx, cy + r - 5.0)
      ..lineTo(cx, cy + 2.5)
      ..lineTo(cx + 3.2, cy)
      ..close();
    canvas.drawPath(southRight, Paint()..color = const Color(0xFF94A3B8)..style = PaintingStyle.fill);

    // 5. Center Pivot Jewel
    canvas.drawCircle(Offset(cx, cy), 3.0, Paint()..color = const Color(0xFF0F172A));
    canvas.drawCircle(Offset(cx, cy), 1.6, Paint()..color = const Color(0xFF10B981));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
