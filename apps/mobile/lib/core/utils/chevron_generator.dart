import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ChevronGenerator {
  static Future<Uint8List> generateChevron({double size = 120.0}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _drawChevron(canvas, size);
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static void _drawChevron(Canvas canvas, double size) {
    final center = Offset(size / 2, size / 2);

    final shadowPaint = Paint()
      ..color = const Color(0xFFFFB800).withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16.0);
    
    final path = Path();
    path.moveTo(center.dx, size * 0.1); 
    path.lineTo(size * 0.9, size * 0.85); 
    path.lineTo(center.dx, size * 0.65); 
    path.lineTo(size * 0.1, size * 0.85); 
    path.close();

    canvas.drawPath(path, shadowPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFF040A14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, borderPaint);

    final gradientPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(center.dx, size * 0.1),
        Offset(center.dx, size * 0.8),
        [
          const Color(0xFFFFF1C1),
          const Color(0xFFFFB800),
          const Color(0xFFCC8400),
        ],
      )
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, gradientPaint);

    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx, size * 0.2), 
      Offset(center.dx, size * 0.55), 
      highlightPaint
    );
  }
}

class PremiumChevronWidget extends StatelessWidget {
  final double size;
  const PremiumChevronWidget({super.key, this.size = 100.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ChevronPainter(size),
      ),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  final double size;
  _ChevronPainter(this.size);

  @override
  void paint(Canvas canvas, Size size) {
    ChevronGenerator._drawChevron(canvas, this.size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
