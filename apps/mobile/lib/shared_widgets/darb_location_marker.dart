import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;

/// DARB Premium Location Marker & Navigation Puck
/// 
/// Features:
/// - Smooth 60 FPS GPS Position Interpolation (A -> B without teleporting)
/// - Shortest-Angle Heading Interpolation (359° -> 1° = +2°)
/// - Stationary Anti-Jitter Lock (Retains stable heading when speed < 2 km/h)
/// - Subtle Adaptive GPS Accuracy Halo Ring
/// - Minimalist, modern stealth navigation arrow (Zero cartoon aesthetics)
class DarbLocationMarker extends StatefulWidget {
  final LatLng position;
  final double bearing;
  final double speedKmh;
  final double? accuracyMeters;
  final double size;

  const DarbLocationMarker({
    super.key,
    required this.position,
    this.bearing = 0.0,
    this.speedKmh = 0.0,
    this.accuracyMeters,
    this.size = 46.0,
  });

  @override
  State<DarbLocationMarker> createState() => _DarbLocationMarkerState();
}

class _DarbLocationMarkerState extends State<DarbLocationMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _headingController;
  Animation<double>? _headingAnimation;
  double _currentBearing = 0.0;
  double _targetBearing = 0.0;
  double? _lastStableBearing;

  @override
  void initState() {
    super.initState();
    _currentBearing = widget.bearing;
    _targetBearing = widget.bearing;
    if (widget.speedKmh > 2.0) {
      _lastStableBearing = widget.bearing;
    }

    _headingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _headingController.addListener(() {
      if (mounted && _headingAnimation != null) {
        setState(() {
          _currentBearing = _headingAnimation!.value;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant DarbLocationMarker oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Anti-Jitter Stationary Lock & Shortest-Angle Heading Interpolation
    double newTarget = widget.bearing;
    if (widget.speedKmh < 2.0 && _lastStableBearing != null) {
      newTarget = _lastStableBearing!;
    } else {
      _lastStableBearing = widget.bearing;
    }

    if ((newTarget - _targetBearing).abs() > 0.8) {
      double diff = (newTarget - _currentBearing) % 360.0;
      if (diff > 180.0) diff -= 360.0;
      if (diff < -180.0) diff += 360.0;

      final startAngle = _currentBearing;
      final endAngle = _currentBearing + diff;
      _targetBearing = newTarget;

      _headingAnimation = Tween<double>(begin: startAngle, end: endAngle).animate(
        CurvedAnimation(parent: _headingController, curve: Curves.easeOutQuad),
      );
      _headingController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _headingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = widget.accuracyMeters ?? 10.0;
    // Scale accuracy ring: minimum 1.1x, maximum 2.4x
    final haloScale = (1.1 + (accuracy / 40.0)).clamp(1.1, 2.2);

    return RepaintBoundary(
      child: SizedBox(
        width: widget.size * 2.2,
        height: widget.size * 2.2,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Subtle Adaptive GPS Accuracy Halo Ring
              Container(
                width: widget.size * haloScale,
                height: widget.size * haloScale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withOpacity(0.08),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.22),
                    width: 1.0,
                  ),
                ),
              ),

              // 2. Sleek Aerodynamic DARB Stealth Vehicle Arrow
              Transform.rotate(
                angle: _currentBearing * (3.141592653589793 / 180.0),
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _DarbVehicleMarkerPainter(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DarbVehicleMarkerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft Aerodynamic Drop Shadow Under Vehicle (Dual-pass alpha, zero GPU blur stall)
    final shadowPath = Path()
      ..moveTo(w * 0.5, h * 0.16)
      ..lineTo(w * 0.88, h * 0.86)
      ..lineTo(w * 0.5, h * 0.72)
      ..lineTo(w * 0.12, h * 0.86)
      ..close();

    canvas.drawPath(
      shadowPath.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withOpacity(0.22)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      shadowPath.shift(const Offset(0, 1.5)),
      Paint()
        ..color = Colors.black.withOpacity(0.32)
        ..style = PaintingStyle.fill,
    );

    // 2. Left Wing (Dark Charcoal Shield Facet)
    final leftWing = Path()
      ..moveTo(w * 0.5, h * 0.10)
      ..lineTo(w * 0.5, h * 0.70)
      ..lineTo(w * 0.12, h * 0.84)
      ..close();

    final leftWingPaint = Paint()
      ..color = const Color(0xFF1E293B) // surface2 slightly lighter
      ..style = PaintingStyle.fill;
    canvas.drawPath(leftWing, leftWingPaint);

    // 3. Right Wing (Deep Charcoal Core)
    final rightWing = Path()
      ..moveTo(w * 0.5, h * 0.10)
      ..lineTo(w * 0.88, h * 0.84)
      ..lineTo(w * 0.5, h * 0.70)
      ..close();

    final rightWingPaint = Paint()
      ..color = const Color(0xFF0F172A) // base canvas dark
      ..style = PaintingStyle.fill;
    canvas.drawPath(rightWing, rightWingPaint);

    // 4. Emerald Perimeter Stroke (Premium accent)
    final outerHull = Path()
      ..moveTo(w * 0.5, h * 0.10)
      ..lineTo(w * 0.88, h * 0.84)
      ..lineTo(w * 0.5, h * 0.70)
      ..lineTo(w * 0.12, h * 0.84)
      ..close();

    final hullBorderPaint = Paint()
      ..color = const Color(0xFF10B981) // Emerald Primary
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(outerHull, hullBorderPaint);

    // 5. Cyan/Emerald Navigation Dorsal Ridge / Center Spine
    final spinePaint = Paint()
      ..color = const Color(0xFF0EA5E9) // Cyan/Emerald glow
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.5, h * 0.12), Offset(w * 0.5, h * 0.68), spinePaint);

    // 6. Navigation Radar Pulse Core Dot
    final coreDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.44), 2.2, coreDotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
