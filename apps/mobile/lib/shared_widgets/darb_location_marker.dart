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
            // 1. Subtle GPS Accuracy Halo Ring
            Container(
              width: widget.size * haloScale,
              height: widget.size * haloScale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withOpacity(0.08),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.25),
                  width: 1.2,
                ),
              ),
            ),

            // 2. High-Precision Navigation Puck & Stealth Arrow
            Transform.rotate(
              angle: _currentBearing * (pi / 180.0),
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _DarbPuckPainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DarbPuckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.5);
    final radius = w * 0.44;

    // 1. Subtle Outer Drop Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    canvas.drawCircle(center.translate(0, 2), radius + 1, shadowPaint);

    // 2. Crisp White Collar Ring
    final whiteRingPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, whiteRingPaint);

    // 3. Deep Titanium Inner Puck Body
    final innerPuckPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF1E293B), // Dark slate
          Color(0xFF0F172A), // Deep navy
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.88))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.86, innerPuckPaint);

    // 4. Precision Stealth Arrowhead (Pointing UP)
    final arrowPath = Path();
    final arrowWidth = w * 0.38;
    final arrowHeight = h * 0.52;
    final arrowTop = h * 0.22;
    final arrowBottom = arrowTop + arrowHeight;

    arrowPath.moveTo(w * 0.5, arrowTop); // Sharp Nose Tip
    arrowPath.lineTo(w * 0.5 + arrowWidth * 0.5, arrowBottom); // Right Wingtip
    arrowPath.lineTo(w * 0.5, arrowBottom - arrowHeight * 0.25); // Inward Tail Notch
    arrowPath.lineTo(w * 0.5 - arrowWidth * 0.5, arrowBottom); // Left Wingtip
    arrowPath.close();

    // Vibrant DARB Emerald Gradient Fill
    final arrowPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF34D399), // Bright emerald highlight
          Color(0xFF059669), // Deep rich emerald
        ],
      ).createShader(Rect.fromLTWH(w * 0.2, arrowTop, arrowWidth, arrowHeight))
      ..style = PaintingStyle.fill;
    canvas.drawPath(arrowPath, arrowPaint);

    // Hairline crisp edge on arrow
    final arrowBorderPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.miter;
    canvas.drawPath(arrowPath, arrowBorderPaint);

    // 5. Center Radar Core Dot
    final coreDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center.translate(0, arrowHeight * 0.08), 2.2, coreDotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
