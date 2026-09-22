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
    with TickerProviderStateMixin {
  late AnimationController _positionController;
  late Animation<double> _posAnimation;
  LatLng _prevPosition = const LatLng(36.1911, 44.0091);
  LatLng _targetPosition = const LatLng(36.1911, 44.0091);

  late AnimationController _headingController;
  late Animation<double> _headingAnimation;
  double _currentBearing = 0.0;
  double _targetBearing = 0.0;
  double? _lastStableBearing;

  @override
  void initState() {
    super.initState();
    _prevPosition = widget.position;
    _targetPosition = widget.position;
    _currentBearing = widget.bearing;
    _targetBearing = widget.bearing;
    if (widget.speedKmh > 2.0) {
      _lastStableBearing = widget.bearing;
    }

    _positionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _posAnimation = CurvedAnimation(
      parent: _positionController,
      curve: Curves.easeOutCubic,
    )..addListener(() => setState(() {}));

    _headingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _headingAnimation = CurvedAnimation(
      parent: _headingController,
      curve: Curves.easeOutQuad,
    )..addListener(() {
        setState(() {
          _currentBearing = _headingAnimation.value;
        });
      });
  }

  @override
  void didUpdateWidget(covariant DarbLocationMarker oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 1. Smooth Position Interpolation (A -> B)
    if (widget.position != _targetPosition) {
      _prevPosition = _currentInterpolatedPosition;
      _targetPosition = widget.position;
      _positionController.forward(from: 0.0);
    }

    // 2. Anti-Jitter Stationary Lock & Shortest-Angle Heading Interpolation
    double newTarget = widget.bearing;
    if (widget.speedKmh < 2.0 && _lastStableBearing != null) {
      // Lock heading when stopped or crawling to prevent GPS sensor drift
      newTarget = _lastStableBearing!;
    } else {
      _lastStableBearing = widget.bearing;
    }

    if ((newTarget - _targetBearing).abs() > 0.5) {
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

  LatLng get _currentInterpolatedPosition {
    final t = _posAnimation.value;
    final lat = _prevPosition.latitude + (_targetPosition.latitude - _prevPosition.latitude) * t;
    final lng = _prevPosition.longitude + (_targetPosition.longitude - _prevPosition.longitude) * t;
    return LatLng(lat, lng);
  }

  @override
  void dispose() {
    _positionController.dispose();
    _headingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = widget.accuracyMeters ?? 10.0;
    // Scale accuracy ring: minimum 1.1x, maximum 2.4x
    final haloScale = (1.1 + (accuracy / 40.0)).clamp(1.1, 2.2);

    return SizedBox(
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
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.22),
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
    );
  }
}

class _DarbVehicleMarkerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft Aerodynamic Drop Shadow Under Vehicle
    final shadowPath = Path()
      ..moveTo(w * 0.5, h * 0.16)
      ..lineTo(w * 0.88, h * 0.86)
      ..lineTo(w * 0.5, h * 0.72)
      ..lineTo(w * 0.12, h * 0.86)
      ..close();

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.38)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawPath(shadowPath.shift(const Offset(0, 3)), shadowPaint);

    // 2. Left Wing (Bright Emerald Highlight)
    final leftWing = Path()
      ..moveTo(w * 0.5, h * 0.10)
      ..lineTo(w * 0.5, h * 0.70)
      ..lineTo(w * 0.12, h * 0.84)
      ..close();

    final leftWingPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF34D399), // Emerald highlight
          Color(0xFF10B981), // Emerald primary
        ],
      ).createShader(Rect.fromLTWH(w * 0.12, h * 0.10, w * 0.38, h * 0.74))
      ..style = PaintingStyle.fill;
    canvas.drawPath(leftWing, leftWingPaint);

    // 3. Right Wing (Deep Emerald Shadow Facet)
    final rightWing = Path()
      ..moveTo(w * 0.5, h * 0.10)
      ..lineTo(w * 0.88, h * 0.84)
      ..lineTo(w * 0.5, h * 0.70)
      ..close();

    final rightWingPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color(0xFF059669), // Rich emerald
          Color(0xFF047857), // Deep emerald shade
        ],
      ).createShader(Rect.fromLTWH(w * 0.5, h * 0.10, w * 0.38, h * 0.74))
      ..style = PaintingStyle.fill;
    canvas.drawPath(rightWing, rightWingPaint);

    // 4. Razor Titanium Outer Hull Border (100% road contrast)
    final outerHull = Path()
      ..moveTo(w * 0.5, h * 0.10)
      ..lineTo(w * 0.88, h * 0.84)
      ..lineTo(w * 0.5, h * 0.70)
      ..lineTo(w * 0.12, h * 0.84)
      ..close();

    final hullBorderPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(outerHull, hullBorderPaint);

    // 5. White Navigation Dorsal Ridge / Center Spine
    final spinePaint = Paint()
      ..color = Colors.white
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
