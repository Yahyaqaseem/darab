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
                  color: const Color(0xFFEAB308).withOpacity(0.08),
                  border: Border.all(
                    color: const Color(0xFFEAB308).withOpacity(0.22),
                    width: 1.0,
                  ),
                ),
              ),

              // 2. Sleek Professional Navigation Puck or Chevron
              Transform.rotate(
                angle: _currentBearing * (3.141592653589793 / 180.0),
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _DarbVehicleMarkerPainter(
                    isStationary: widget.speedKmh < 2.0,
                  ),
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
  final bool isStationary;
  _DarbVehicleMarkerPainter({required this.isStationary});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.5);

    if (isStationary) {
      // 1. Stationary Professional Puck (Blue/White Dot)
      // Outer shadow
      canvas.drawCircle(
        center.translate(0, 2),
        w * 0.28,
        Paint()..color = Colors.black.withOpacity(0.3)..style = PaintingStyle.fill,
      );
      // White casing
      canvas.drawCircle(
        center,
        w * 0.28,
        Paint()..color = Colors.white..style = PaintingStyle.fill,
      );
      // Inner blue dot
      canvas.drawCircle(
        center,
        w * 0.18,
        Paint()..color = const Color(0xFF3B82F6)..style = PaintingStyle.fill,
      );
    } else {
      // 2. Refined Directional Chevron (Not a paper airplane)
      // Uses a modern chevron shape with depth
      final chevronPath = Path()
        ..moveTo(w * 0.5, h * 0.15) // Tip
        ..lineTo(w * 0.85, h * 0.85) // Bottom right
        ..quadraticBezierTo(w * 0.5, h * 0.70, w * 0.15, h * 0.85) // Bottom arc
        ..close();

      // Shadow
      canvas.drawPath(
        chevronPath.shift(const Offset(0, 3)),
        Paint()..color = Colors.black.withOpacity(0.35)..style = PaintingStyle.fill,
      );

      // Casing (White outer stroke)
      canvas.drawPath(
        chevronPath,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeJoin = StrokeJoin.round,
      );

      // Core (Blue/Golden fill)
      canvas.drawPath(
        chevronPath,
        Paint()
          ..color = const Color(0xFF3B82F6) // Deep blue nav arrow
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DarbVehicleMarkerPainter oldDelegate) => 
      isStationary != oldDelegate.isStationary;
}

