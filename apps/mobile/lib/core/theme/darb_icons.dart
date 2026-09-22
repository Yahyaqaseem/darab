import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/models/models.dart';

/// DARB Unified Icon Types
enum DarbIconType {
  // Navigation & Controls
  menu,
  search,
  profile,
  notifications,
  settings,
  back,
  close,
  myLocation,
  recenter,
  compass,
  zoomIn,
  zoomOut,
  layers,
  trafficFlow,
  route,
  share,
  home,
  work,
  add,

  // Road Reports (11 Types)
  accident,
  traffic,
  checkpoint,
  pothole,
  closure,
  roadworks,
  danger,
  flood,
  brokenCar,
  badRoad,
  radar,
  otherReport,

  // Places & POIs (14 Types)
  fuel,
  restaurant,
  cafe,
  hotel,
  workshop,
  tireRepair,
  carWash,
  parking,
  pharmacy,
  hospital,
  store,
  evCharging,
  atm,
  civic,
  phone,
  battery,

  // Quick Actions & Emergency
  roadCall,
  quickReport,
  sos,
}

/// Standardized DARB Icon Sizing System
class DarbIconSizes {
  static const double tiny = 14.0;
  static const double small = 18.0;
  static const double normal = 22.0;
  static const double navigation = 26.0;
  static const double primaryMarker = 38.0;
  static const double emergency = 48.0;
}

/// Standardized DARB Semantic Colors
class DarbIconColors {
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldDark = Color(0xFF059669);
  static const Color charcoal = Color(0xFF1E293B);
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color offWhite = Color(0xFFF8FAFC);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color criticalRed = Color(0xFFEF4444);
  static const Color checkpointBlue = Color(0xFF3B82F6);
  static const Color radarCyan = Color(0xFF0EA5E9);
  static const Color slate = Color(0xFF64748B);
  static const Color purple = Color(0xFF8B5CF6);
}

/// High-Performance Vector DARB Icon
class DarbIcon extends StatelessWidget {
  final DarbIconType type;
  final double size;
  final Color? color;
  final double strokeWidth;

  const DarbIcon(
    this.type, {
    super.key,
    this.size = DarbIconSizes.normal,
    this.color,
    this.strokeWidth = 1.9,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? (Theme.of(context).brightness == Brightness.dark ? DarbIconColors.offWhite : DarbIconColors.charcoal);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _DarbIconPainter(
          type: type,
          color: effectiveColor,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _DarbIconPainter extends CustomPainter {
  final DarbIconType type;
  final Color color;
  final double strokeWidth;

  _DarbIconPainter({
    required this.type,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0; // scale factor from 24x24 grid
    final paintStroke = Paint()
      ..color = color
      ..strokeWidth = strokeWidth * s
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final paintFill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (type) {
      // 1. Menu (2-tier geometric sleek bars)
      case DarbIconType.menu:
        canvas.drawLine(Offset(4 * s, 8 * s), Offset(20 * s, 8 * s), paintStroke);
        canvas.drawLine(Offset(4 * s, 14 * s), Offset(15 * s, 14 * s), paintStroke);
        canvas.drawLine(Offset(4 * s, 20 * s), Offset(18 * s, 20 * s), paintStroke);
        break;

      // 2. Search (Geometric lens with 45° angled handle)
      case DarbIconType.search:
        canvas.drawCircle(Offset(10.5 * s, 10.5 * s), 6.5 * s, paintStroke);
        canvas.drawLine(Offset(15.5 * s, 15.5 * s), Offset(20.5 * s, 20.5 * s), paintStroke);
        break;

      // 3. Profile
      case DarbIconType.profile:
        canvas.drawCircle(Offset(12 * s, 8 * s), 4 * s, paintStroke);
        final bodyPath = Path()
          ..moveTo(5 * s, 20 * s)
          ..cubicTo(5 * s, 15.5 * s, 8 * s, 14.5 * s, 12 * s, 14.5 * s)
          ..cubicTo(16 * s, 14.5 * s, 19 * s, 15.5 * s, 19 * s, 20 * s);
        canvas.drawPath(bodyPath, paintStroke);
        break;

      // 4. Notifications (Bell)
      case DarbIconType.notifications:
        final bell = Path()
          ..moveTo(12 * s, 4 * s)
          ..cubicTo(8.5 * s, 4 * s, 7 * s, 7 * s, 7 * s, 11 * s)
          ..lineTo(5.5 * s, 16.5 * s)
          ..lineTo(18.5 * s, 16.5 * s)
          ..lineTo(17 * s, 11 * s)
          ..cubicTo(17 * s, 7 * s, 15.5 * s, 4 * s, 12 * s, 4 * s)
          ..close();
        canvas.drawPath(bell, paintStroke);
        canvas.drawArc(Rect.fromCircle(center: Offset(12 * s, 17 * s), radius: 2.5 * s), 0, math.pi, false, paintStroke);
        break;

      // 5. Settings (Gear)
      case DarbIconType.settings:
        canvas.drawCircle(Offset(12 * s, 12 * s), 3.5 * s, paintStroke);
        final gear = Path();
        for (int i = 0; i < 6; i++) {
          final angle = i * (math.pi / 3);
          final p1 = Offset(12 * s + 8.5 * s * math.cos(angle - 0.2), 12 * s + 8.5 * s * math.sin(angle - 0.2));
          final p2 = Offset(12 * s + 8.5 * s * math.cos(angle + 0.2), 12 * s + 8.5 * s * math.sin(angle + 0.2));
          final p3 = Offset(12 * s + 6.5 * s * math.cos(angle + 0.35), 12 * s + 6.5 * s * math.sin(angle + 0.35));
          if (i == 0) gear.moveTo(p1.dx, p1.dy); else gear.lineTo(p1.dx, p1.dy);
          gear.lineTo(p2.dx, p2.dy);
          gear.lineTo(p3.dx, p3.dy);
        }
        gear.close();
        canvas.drawPath(gear, paintStroke);
        break;

      // 6. Back (Chevron)
      case DarbIconType.back:
        final chevron = Path()
          ..moveTo(14.5 * s, 6 * s)
          ..lineTo(8.5 * s, 12 * s)
          ..lineTo(14.5 * s, 18 * s);
        canvas.drawPath(chevron, paintStroke);
        break;

      // 7. Close (X)
      case DarbIconType.close:
        canvas.drawLine(Offset(6 * s, 6 * s), Offset(18 * s, 18 * s), paintStroke);
        canvas.drawLine(Offset(18 * s, 6 * s), Offset(6 * s, 18 * s), paintStroke);
        break;

      // 8. MyLocation (Crosshair Target)
      case DarbIconType.myLocation:
        canvas.drawCircle(Offset(12 * s, 12 * s), 6 * s, paintStroke);
        canvas.drawCircle(Offset(12 * s, 12 * s), 2.5 * s, paintFill);
        canvas.drawLine(Offset(12 * s, 2 * s), Offset(12 * s, 5 * s), paintStroke);
        canvas.drawLine(Offset(12 * s, 19 * s), Offset(12 * s, 22 * s), paintStroke);
        canvas.drawLine(Offset(2 * s, 12 * s), Offset(5 * s, 12 * s), paintStroke);
        canvas.drawLine(Offset(19 * s, 12 * s), Offset(22 * s, 12 * s), paintStroke);
        break;

      // 9. Recenter (Navigation Pointer Target)
      case DarbIconType.recenter:
        final navArrow = Path()
          ..moveTo(12 * s, 4 * s)
          ..lineTo(19 * s, 19 * s)
          ..lineTo(12 * s, 15.5 * s)
          ..lineTo(5 * s, 19 * s)
          ..close();
        canvas.drawPath(navArrow, paintFill);
        break;

      // 10. Compass
      case DarbIconType.compass:
        canvas.drawCircle(Offset(12 * s, 12 * s), 9 * s, paintStroke);
        final north = Path()
          ..moveTo(12 * s, 5 * s)
          ..lineTo(14.5 * s, 12 * s)
          ..lineTo(12 * s, 10.5 * s)
          ..lineTo(9.5 * s, 12 * s)
          ..close();
        final south = Path()
          ..moveTo(12 * s, 19 * s)
          ..lineTo(14.5 * s, 12 * s)
          ..lineTo(12 * s, 13.5 * s)
          ..lineTo(9.5 * s, 12 * s)
          ..close();
        canvas.drawPath(north, paintFill);
        canvas.drawPath(south, paintStroke);
        break;

      // 11. ZoomIn / ZoomOut
      case DarbIconType.zoomIn:
        canvas.drawLine(Offset(6 * s, 12 * s), Offset(18 * s, 12 * s), paintStroke);
        canvas.drawLine(Offset(12 * s, 6 * s), Offset(12 * s, 18 * s), paintStroke);
        break;
      case DarbIconType.zoomOut:
        canvas.drawLine(Offset(6 * s, 12 * s), Offset(18 * s, 12 * s), paintStroke);
        break;

      // 12. Layers
      case DarbIconType.layers:
        final layerTop = Path()
          ..moveTo(12 * s, 4 * s)
          ..lineTo(20 * s, 8.5 * s)
          ..lineTo(12 * s, 13 * s)
          ..lineTo(4 * s, 8.5 * s)
          ..close();
        canvas.drawPath(layerTop, paintStroke);
        final layerBottom = Path()
          ..moveTo(4 * s, 12.5 * s)
          ..lineTo(12 * s, 17 * s)
          ..lineTo(20 * s, 12.5 * s);
        canvas.drawPath(layerBottom, paintStroke);
        final layerBase = Path()
          ..moveTo(4 * s, 16.5 * s)
          ..lineTo(12 * s, 21 * s)
          ..lineTo(20 * s, 16.5 * s);
        canvas.drawPath(layerBase, paintStroke);
        break;

      // 13. Home
      case DarbIconType.home:
        final roof = Path()
          ..moveTo(3.5 * s, 10.5 * s)
          ..lineTo(12 * s, 3.5 * s)
          ..lineTo(20.5 * s, 10.5 * s);
        canvas.drawPath(roof, paintStroke);
        final house = Path()
          ..moveTo(6 * s, 10.5 * s)
          ..lineTo(6 * s, 19.5 * s)
          ..lineTo(18 * s, 19.5 * s)
          ..lineTo(18 * s, 10.5 * s);
        canvas.drawPath(house, paintStroke);
        canvas.drawLine(Offset(10 * s, 19.5 * s), Offset(10 * s, 14.5 * s), paintStroke);
        canvas.drawLine(Offset(14 * s, 19.5 * s), Offset(14 * s, 14.5 * s), paintStroke);
        canvas.drawLine(Offset(10 * s, 14.5 * s), Offset(14 * s, 14.5 * s), paintStroke);
        break;

      // 14. Work (Briefcase)
      case DarbIconType.work:
        final bag = RRect.fromRectAndRadius(Rect.fromLTWH(4 * s, 8 * s, 16 * s, 12 * s), Radius.circular(3 * s));
        canvas.drawRRect(bag, paintStroke);
        final handle = Path()
          ..moveTo(8.5 * s, 8 * s)
          ..lineTo(8.5 * s, 5 * s)
          ..lineTo(15.5 * s, 5 * s)
          ..lineTo(15.5 * s, 8 * s);
        canvas.drawPath(handle, paintStroke);
        canvas.drawLine(Offset(4 * s, 13 * s), Offset(20 * s, 13 * s), paintStroke);
        break;

      // 15. Add
      case DarbIconType.add:
        canvas.drawLine(Offset(5 * s, 12 * s), Offset(19 * s, 12 * s), paintStroke);
        canvas.drawLine(Offset(12 * s, 5 * s), Offset(12 * s, 19 * s), paintStroke);
        break;

      // --- ROAD REPORTS (11 TYPES) ---

      // 16. Accident (Two colliding vehicle silhouettes with impact burst)
      case DarbIconType.accident:
        // Left Car Chevron
        final carL = Path()
          ..moveTo(4 * s, 7 * s)
          ..lineTo(10 * s, 10 * s)
          ..lineTo(10 * s, 14 * s)
          ..lineTo(4 * s, 17 * s);
        canvas.drawPath(carL, paintStroke);
        // Right Car Chevron
        final carR = Path()
          ..moveTo(20 * s, 7 * s)
          ..lineTo(14 * s, 10 * s)
          ..lineTo(14 * s, 14 * s)
          ..lineTo(20 * s, 17 * s);
        canvas.drawPath(carR, paintStroke);
        // Central Impact Spark
        canvas.drawLine(Offset(12 * s, 4 * s), Offset(12 * s, 20 * s), paintStroke);
        canvas.drawLine(Offset(9 * s, 8 * s), Offset(15 * s, 16 * s), paintStroke);
        canvas.drawLine(Offset(15 * s, 8 * s), Offset(9 * s, 16 * s), paintStroke);
        break;

      // 17. Traffic (Congestion / Multiple Vehicles in Staggered Flow)
      case DarbIconType.traffic:
        // Lead vehicle
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(8 * s, 4 * s, 8 * s, 4.5 * s), Radius.circular(1.5 * s)), paintFill);
        // Follower vehicle
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(5 * s, 10 * s, 8 * s, 4.5 * s), Radius.circular(1.5 * s)), paintFill);
        // Third vehicle
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(11 * s, 15.5 * s, 8 * s, 4.5 * s), Radius.circular(1.5 * s)), paintFill);
        break;

      // 18. Checkpoint (Security Gate with Guard Barrier)
      case DarbIconType.checkpoint:
        // Left Post
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(4 * s, 12 * s, 3.5 * s, 8 * s), Radius.circular(1 * s)), paintFill);
        // Barrier Boom Arm angled up
        final boom = Path()
          ..moveTo(6 * s, 13 * s)
          ..lineTo(19 * s, 7 * s);
        canvas.drawPath(boom, paintStroke);
        // Stop disc
        canvas.drawCircle(Offset(12.5 * s, 10 * s), 2.5 * s, paintFill);
        break;

      // 19. Pothole (Road Surface with Depression Void)
      case DarbIconType.pothole:
        // Road surface line left
        canvas.drawLine(Offset(3 * s, 12 * s), Offset(7 * s, 12 * s), paintStroke);
        // Depression crater
        final crater = Path()
          ..moveTo(7 * s, 12 * s)
          ..cubicTo(8 * s, 18 * s, 16 * s, 18 * s, 17 * s, 12 * s);
        canvas.drawPath(crater, paintStroke);
        // Road surface line right
        canvas.drawLine(Offset(17 * s, 12 * s), Offset(21 * s, 12 * s), paintStroke);
        // Crack lines inside
        canvas.drawLine(Offset(10 * s, 14 * s), Offset(12 * s, 16 * s), paintStroke);
        canvas.drawLine(Offset(12 * s, 16 * s), Offset(14 * s, 14 * s), paintStroke);
        break;

      // 20. Closure (Blocked Road / Barrier)
      case DarbIconType.closure:
        canvas.drawCircle(Offset(12 * s, 12 * s), 8.5 * s, paintStroke);
        canvas.drawLine(Offset(6 * s, 12 * s), Offset(18 * s, 12 * s), Paint()
          ..color = color
          ..strokeWidth = 3.5 * s
          ..strokeCap = StrokeCap.round);
        break;

      // 21. Roadworks (Construction Cone)
      case DarbIconType.roadworks:
        // Base plate
        canvas.drawLine(Offset(4 * s, 20 * s), Offset(20 * s, 20 * s), paintStroke);
        // Cone body
        final cone = Path()
          ..moveTo(6 * s, 19.5 * s)
          ..lineTo(11 * s, 4 * s)
          ..lineTo(13 * s, 4 * s)
          ..lineTo(18 * s, 19.5 * s)
          ..close();
        canvas.drawPath(cone, paintStroke);
        // Stripes
        canvas.drawLine(Offset(8.5 * s, 13 * s), Offset(15.5 * s, 13 * s), paintStroke);
        canvas.drawLine(Offset(10 * s, 9 * s), Offset(14 * s, 9 * s), paintStroke);
        break;

      // 22. Danger (Equilateral Warning Triangle)
      case DarbIconType.danger:
        final tri = Path()
          ..moveTo(12 * s, 4 * s)
          ..lineTo(21 * s, 19.5 * s)
          ..lineTo(3 * s, 19.5 * s)
          ..close();
        canvas.drawPath(tri, paintStroke);
        // Exclamation mark
        canvas.drawLine(Offset(12 * s, 9 * s), Offset(12 * s, 14 * s), Paint()
          ..color = color
          ..strokeWidth = 2.2 * s
          ..strokeCap = StrokeCap.round);
        canvas.drawCircle(Offset(12 * s, 16.5 * s), 1.2 * s, paintFill);
        break;

      // 23. Flood (Water waves over road)
      case DarbIconType.flood:
        // Top wave
        final wave1 = Path()
          ..moveTo(3 * s, 10 * s)
          ..cubicTo(6 * s, 7 * s, 9 * s, 13 * s, 12 * s, 10 * s)
          ..cubicTo(15 * s, 7 * s, 18 * s, 13 * s, 21 * s, 10 * s);
        canvas.drawPath(wave1, paintStroke);
        // Bottom wave
        final wave2 = Path()
          ..moveTo(3 * s, 15 * s)
          ..cubicTo(6 * s, 12 * s, 9 * s, 18 * s, 12 * s, 15 * s)
          ..cubicTo(15 * s, 12 * s, 18 * s, 18 * s, 21 * s, 15 * s);
        canvas.drawPath(wave2, paintStroke);
        canvas.drawLine(Offset(4 * s, 20 * s), Offset(20 * s, 20 * s), paintStroke);
        break;

      // 24. BrokenCar (Disabled vehicle)
      case DarbIconType.brokenCar:
        // Car outline
        final body = Path()
          ..moveTo(4 * s, 15 * s)
          ..lineTo(5 * s, 11 * s)
          ..lineTo(8 * s, 11 * s)
          ..lineTo(10 * s, 7.5 * s)
          ..lineTo(16 * s, 7.5 * s)
          ..lineTo(19 * s, 11 * s)
          ..lineTo(20 * s, 15 * s)
          ..close();
        canvas.drawPath(body, paintStroke);
        // Wheels
        canvas.drawCircle(Offset(7.5 * s, 15 * s), 2 * s, paintFill);
        canvas.drawCircle(Offset(16.5 * s, 15 * s), 2 * s, paintFill);
        // Warning wrench/hood steam
        canvas.drawLine(Offset(12 * s, 4 * s), Offset(12 * s, 7 * s), paintStroke);
        break;

      // 25. BadRoad (Uneven damaged asphalt)
      case DarbIconType.badRoad:
        final uneven = Path()
          ..moveTo(3 * s, 14 * s)
          ..lineTo(7 * s, 9 * s)
          ..lineTo(11 * s, 16 * s)
          ..lineTo(15 * s, 8 * s)
          ..lineTo(21 * s, 14 * s);
        canvas.drawPath(uneven, paintStroke);
        canvas.drawLine(Offset(3 * s, 19 * s), Offset(21 * s, 19 * s), paintStroke);
        break;

      // 26. Radar / Speed Camera
      case DarbIconType.radar:
        final camBody = RRect.fromRectAndRadius(Rect.fromLTWH(4 * s, 8 * s, 16 * s, 11 * s), Radius.circular(2.5 * s));
        canvas.drawRRect(camBody, paintStroke);
        canvas.drawCircle(Offset(12 * s, 13.5 * s), 3.5 * s, paintStroke);
        canvas.drawCircle(Offset(12 * s, 13.5 * s), 1.5 * s, paintFill);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(8 * s, 5 * s, 5 * s, 3 * s), Radius.circular(1 * s)), paintStroke);
        break;

      // 27. OtherReport
      case DarbIconType.otherReport:
        canvas.drawCircle(Offset(12 * s, 12 * s), 8.5 * s, paintStroke);
        canvas.drawCircle(Offset(12 * s, 8 * s), 1.2 * s, paintFill);
        canvas.drawLine(Offset(12 * s, 11 * s), Offset(12 * s, 16 * s), paintStroke);
        break;

      // --- PLACES & SERVICES (14 TYPES) ---

      // 28. Fuel Station (Geometric DARB Fuel Pump with Hose Detail)
      case DarbIconType.fuel:
        // Pump Body
        final pump = RRect.fromRectAndRadius(Rect.fromLTWH(4 * s, 5 * s, 10 * s, 15 * s), Radius.circular(2 * s));
        canvas.drawRRect(pump, paintStroke);
        // Fuel Meter Display Window
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(6.5 * s, 8 * s, 5 * s, 3.5 * s), Radius.circular(1 * s)), paintStroke);
        // Hose & Nozzle Gun
        final hose = Path()
          ..moveTo(14 * s, 9 * s)
          ..lineTo(17 * s, 9 * s)
          ..cubicTo(19 * s, 9 * s, 19 * s, 16 * s, 17 * s, 16 * s)
          ..lineTo(17 * s, 11 * s);
        canvas.drawPath(hose, paintStroke);
        // Base plate
        canvas.drawLine(Offset(3 * s, 20 * s), Offset(15 * s, 20 * s), paintStroke);
        break;

      // 29. Restaurant (Fork and Knife)
      case DarbIconType.restaurant:
        // Fork
        canvas.drawLine(Offset(7 * s, 4 * s), Offset(7 * s, 20 * s), paintStroke);
        canvas.drawLine(Offset(5 * s, 4 * s), Offset(5 * s, 10 * s), paintStroke);
        canvas.drawLine(Offset(9 * s, 4 * s), Offset(9 * s, 10 * s), paintStroke);
        canvas.drawLine(Offset(5 * s, 10 * s), Offset(9 * s, 10 * s), paintStroke);
        // Knife
        final knife = Path()
          ..moveTo(16 * s, 4 * s)
          ..lineTo(18 * s, 4 * s)
          ..lineTo(18 * s, 11 * s)
          ..lineTo(16 * s, 13 * s)
          ..lineTo(16 * s, 20 * s);
        canvas.drawPath(knife, paintStroke);
        break;

      // 30. Cafe (Coffee Cup)
      case DarbIconType.cafe:
        final cup = Path()
          ..moveTo(5 * s, 8 * s)
          ..lineTo(17 * s, 8 * s)
          ..cubicTo(17 * s, 16 * s, 5 * s, 16 * s, 5 * s, 8 * s)
          ..close();
        canvas.drawPath(cup, paintStroke);
        // Handle
        canvas.drawArc(Rect.fromLTWH(15 * s, 9 * s, 5 * s, 4 * s), -math.pi / 2, math.pi, false, paintStroke);
        // Saucer
        canvas.drawLine(Offset(4 * s, 18 * s), Offset(18 * s, 18 * s), paintStroke);
        break;

      // 31. Workshop (Wrench)
      case DarbIconType.workshop:
        final wrench = Path()
          ..moveTo(6 * s, 9 * s)
          ..lineTo(9 * s, 6 * s)
          ..lineTo(18 * s, 15 * s)
          ..lineTo(15 * s, 18 * s)
          ..close();
        canvas.drawPath(wrench, paintStroke);
        canvas.drawLine(Offset(13.5 * s, 13.5 * s), Offset(19.5 * s, 19.5 * s), paintStroke);
        break;

      // 32. Tire Repair (Wheel with Tread)
      case DarbIconType.tireRepair:
        canvas.drawCircle(Offset(12 * s, 12 * s), 8 * s, paintStroke);
        canvas.drawCircle(Offset(12 * s, 12 * s), 4 * s, paintStroke);
        canvas.drawCircle(Offset(12 * s, 12 * s), 1.5 * s, paintFill);
        break;

      // 33. Parking (Clean Geometric 'P')
      case DarbIconType.parking:
        final pBox = RRect.fromRectAndRadius(Rect.fromLTWH(4 * s, 4 * s, 16 * s, 16 * s), Radius.circular(3 * s));
        canvas.drawRRect(pBox, paintStroke);
        final pLetter = Path()
          ..moveTo(9.5 * s, 16 * s)
          ..lineTo(9.5 * s, 8 * s)
          ..lineTo(13.5 * s, 8 * s)
          ..cubicTo(15.5 * s, 8 * s, 15.5 * s, 12 * s, 13.5 * s, 12 * s)
          ..lineTo(9.5 * s, 12 * s);
        canvas.drawPath(pLetter, paintStroke);
        break;

      // 34. Pharmacy (Medical Cross in Circle)
      case DarbIconType.pharmacy:
        canvas.drawCircle(Offset(12 * s, 12 * s), 8.5 * s, paintStroke);
        canvas.drawLine(Offset(8 * s, 12 * s), Offset(16 * s, 12 * s), Paint()
          ..color = color
          ..strokeWidth = 2.5 * s
          ..strokeCap = StrokeCap.round);
        canvas.drawLine(Offset(12 * s, 8 * s), Offset(12 * s, 16 * s), Paint()
          ..color = color
          ..strokeWidth = 2.5 * s
          ..strokeCap = StrokeCap.round);
        break;

      // 35. Hospital (Bold Emblem)
      case DarbIconType.hospital:
        final hBox = RRect.fromRectAndRadius(Rect.fromLTWH(4 * s, 4 * s, 16 * s, 16 * s), Radius.circular(3 * s));
        canvas.drawRRect(hBox, paintStroke);
        canvas.drawLine(Offset(8.5 * s, 8 * s), Offset(8.5 * s, 16 * s), Paint()
          ..color = color
          ..strokeWidth = 2.2 * s
          ..strokeCap = StrokeCap.round);
        canvas.drawLine(Offset(15.5 * s, 8 * s), Offset(15.5 * s, 16 * s), Paint()
          ..color = color
          ..strokeWidth = 2.2 * s
          ..strokeCap = StrokeCap.round);
        canvas.drawLine(Offset(8.5 * s, 12 * s), Offset(15.5 * s, 12 * s), Paint()
          ..color = color
          ..strokeWidth = 2.2 * s
          ..strokeCap = StrokeCap.round);
        break;

      // 36. Road Call (نداء الطريق - Speech Waves + Navigation Beacon)
      case DarbIconType.roadCall:
        canvas.drawCircle(Offset(12 * s, 15 * s), 2.5 * s, paintFill);
        canvas.drawArc(Rect.fromCircle(center: Offset(12 * s, 15 * s), radius: 6 * s), -math.pi * 0.8, math.pi * 0.6, false, paintStroke);
        canvas.drawArc(Rect.fromCircle(center: Offset(12 * s, 15 * s), radius: 10 * s), -math.pi * 0.8, math.pi * 0.6, false, paintStroke);
        break;

      // 37. Quick Report (بلاغ سريع - Warning Badge with Exclamation)
      case DarbIconType.quickReport:
        final shield = Path()
          ..moveTo(12 * s, 4 * s)
          ..lineTo(19 * s, 7 * s)
          ..lineTo(19 * s, 13 * s)
          ..cubicTo(19 * s, 18 * s, 12 * s, 21 * s, 12 * s, 21 * s)
          ..cubicTo(12 * s, 21 * s, 5 * s, 18 * s, 5 * s, 13 * s)
          ..lineTo(5 * s, 7 * s)
          ..close();
        canvas.drawPath(shield, paintStroke);
        canvas.drawLine(Offset(12 * s, 8.5 * s), Offset(12 * s, 13.5 * s), paintStroke);
        canvas.drawCircle(Offset(12 * s, 16 * s), 1.2 * s, paintFill);
        break;

      // 38. SOS (Typography rendered directly)
      case DarbIconType.sos:
        canvas.drawCircle(Offset(12 * s, 12 * s), 9.5 * s, paintStroke);
        final tp = TextPainter(
          text: TextSpan(
            text: 'SOS',
            style: TextStyle(
              fontSize: 8.5 * s,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(12 * s - tp.width / 2, 12 * s - tp.height / 2));
        break;

      // 39. Phone Handset
      case DarbIconType.phone:
        final phonePath = Path()
          ..moveTo(6.5 * s, 4.5 * s)
          ..cubicTo(6.5 * s, 4.5 * s, 9 * s, 4 * s, 10.5 * s, 7 * s)
          ..lineTo(9.5 * s, 8.5 * s)
          ..cubicTo(10.5 * s, 10.5 * s, 13.5 * s, 13.5 * s, 15.5 * s, 14.5 * s)
          ..lineTo(17 * s, 13.5 * s)
          ..cubicTo(20 * s, 15 * s, 19.5 * s, 17.5 * s, 19.5 * s, 17.5 * s)
          ..cubicTo(19.5 * s, 19.5 * s, 17.5 * s, 20 * s, 16 * s, 20 * s)
          ..cubicTo(9.5 * s, 20 * s, 4 * s, 14.5 * s, 4 * s, 8 * s)
          ..cubicTo(4 * s, 6.5 * s, 4.5 * s, 4.5 * s, 6.5 * s, 4.5 * s);
        canvas.drawPath(phonePath, paintStroke);
        break;

      // 40. Battery (Vehicle Battery)
      case DarbIconType.battery:
        final bBox = RRect.fromRectAndRadius(Rect.fromLTWH(4 * s, 7 * s, 16 * s, 12 * s), Radius.circular(2.5 * s));
        canvas.drawRRect(bBox, paintStroke);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(6.5 * s, 4.5 * s, 3.5 * s, 2.5 * s), Radius.circular(0.8 * s)), paintFill);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(14 * s, 4.5 * s, 3.5 * s, 2.5 * s), Radius.circular(0.8 * s)), paintFill);
        final bolt = Path()
          ..moveTo(12.5 * s, 9 * s)
          ..lineTo(9.5 * s, 13.5 * s)
          ..lineTo(12 * s, 13.5 * s)
          ..lineTo(11.5 * s, 17 * s)
          ..lineTo(14.5 * s, 12.5 * s)
          ..lineTo(12 * s, 12.5 * s)
          ..close();
        canvas.drawPath(bolt, paintStroke);
        break;

      default:
        // Generic fallback clean dot
        canvas.drawCircle(Offset(12 * s, 12 * s), 5 * s, paintStroke);
        canvas.drawCircle(Offset(12 * s, 12 * s), 2 * s, paintFill);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _DarbIconPainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// Standardized DARB Circular / Rounded Map Control Button
class DarbIconButton extends StatelessWidget {
  final DarbIconType icon;
  final VoidCallback onTap;
  final String? tooltip;
  final double size;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool isSelected;
  final Widget? badge;

  const DarbIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 44.0,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
    this.isSelected = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ?? (isDark ? DarbIconColors.charcoal : Colors.white).withValues(alpha: 0.94);
    final border = borderColor ?? (isSelected ? DarbIconColors.emerald : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08)));
    final icColor = iconColor ?? (isSelected ? DarbIconColors.emerald : (isDark ? DarbIconColors.offWhite : DarbIconColors.charcoal));

    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: border, width: isSelected ? 1.8 : 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              DarbIcon(
                icon,
                size: size * 0.48,
                color: icColor,
              ),
              if (badge != null)
                Positioned(
                  top: 2,
                  right: 2,
                  child: badge!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Serious, High-Visibility Circular Emergency SOS Control
class DarbSOSButton extends StatelessWidget {
  final VoidCallback onTap;
  final double size;

  const DarbSOSButton({
    super.key,
    required this.onTap,
    this.size = DarbIconSizes.emergency,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: DarbIconColors.criticalRed,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.9),
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: DarbIconColors.criticalRed.withValues(alpha: 0.45),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'SOS',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

/// Report Status State Enum
enum DarbReportState { active, confirmed, expiring, expired, resolved }

/// Unified Road Report Map Marker
class DarbReportMarker extends StatelessWidget {
  final RoadReportModel? report;
  final DarbIconType? overrideType;
  final DarbReportState state;
  final VoidCallback? onTap;
  final double size;

  const DarbReportMarker({
    super.key,
    this.report,
    this.overrideType,
    this.state = DarbReportState.active,
    this.onTap,
    this.size = DarbIconSizes.primaryMarker,
  });

  DarbIconType get iconType {
    if (overrideType != null) return overrideType!;
    if (report == null) return DarbIconType.danger;
    final t = report!.type.toUpperCase();
    if (t.contains('ACCIDENT') || t.contains('CRASH')) return DarbIconType.accident;
    if (t.contains('TRAFFIC') || t.contains('JAM')) return DarbIconType.traffic;
    if (t.contains('CHECKPOINT') || t.contains('POLICE')) return DarbIconType.checkpoint;
    if (t.contains('POTHOLE')) return DarbIconType.pothole;
    if (t.contains('CLOSURE')) return DarbIconType.closure;
    if (t.contains('ROADWORKS') || t.contains('WORK')) return DarbIconType.roadworks;
    if (t.contains('FLOOD') || t.contains('WATER')) return DarbIconType.flood;
    if (t.contains('BROKEN') || t.contains('CAR')) return DarbIconType.brokenCar;
    if (t.contains('BAD') || t.contains('ROUGH')) return DarbIconType.badRoad;
    if (t.contains('RADAR') || t.contains('CAMERA')) return DarbIconType.radar;
    return DarbIconType.danger;
  }

  Color get semanticColor {
    switch (iconType) {
      case DarbIconType.accident:
      case DarbIconType.closure:
        return DarbIconColors.criticalRed;
      case DarbIconType.traffic:
      case DarbIconType.danger:
      case DarbIconType.roadworks:
        return DarbIconColors.warningOrange;
      case DarbIconType.checkpoint:
        return DarbIconColors.checkpointBlue;
      case DarbIconType.radar:
        return DarbIconColors.radarCyan;
      case DarbIconType.pothole:
      case DarbIconType.badRoad:
        return const Color(0xFFD97706);
      case DarbIconType.flood:
        return const Color(0xFF06B6D4);
      case DarbIconType.brokenCar:
        return DarbIconColors.slate;
      default:
        return DarbIconColors.warningOrange;
    }
  }

  DarbReportState get computedState {
    if (state != DarbReportState.active) return state;
    if (report == null) return DarbReportState.active;
    if (report!.status.toUpperCase() == 'RESOLVED') return DarbReportState.resolved;
    if (report!.confirmationsCount >= 3) return DarbReportState.confirmed;
    final remaining = report!.expiresAt.difference(DateTime.now()).inMinutes;
    if (remaining <= 0) return DarbReportState.expired;
    if (remaining <= 5) return DarbReportState.expiring;
    return DarbReportState.active;
  }

  @override
  Widget build(BuildContext context) {
    final st = computedState;
    if (st == DarbReportState.resolved || st == DarbReportState.expired) {
      return const SizedBox.shrink();
    }

    final opacity = st == DarbReportState.expiring ? 0.65 : 1.0;
    final color = semanticColor;

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size * 1.15,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              CustomPaint(
                size: Size(size, size * 1.15),
                painter: _DarbMarkerPinPainter(
                  pinColor: color,
                  isConfirmed: st == DarbReportState.confirmed,
                ),
              ),
              Positioned(
                top: size * 0.14,
                child: DarbIcon(
                  iconType,
                  size: size * 0.52,
                  color: Colors.white,
                ),
              ),
              if (st == DarbReportState.confirmed)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: DarbIconColors.emerald,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(Icons.check, size: 8, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DarbMarkerPinPainter extends CustomPainter {
  final Color pinColor;
  final bool isConfirmed;

  _DarbMarkerPinPainter({required this.pinColor, this.isConfirmed = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w * 0.44;
    final center = Offset(w * 0.5, r);

    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(Offset(w * 0.5, h * 0.92), 4.0, shadowPaint);

    // Pin body path (Smooth Teardrop Pin)
    final pinPath = Path()
      ..arcTo(Rect.fromCircle(center: center, radius: r), math.pi * 0.8, math.pi * 1.4, false)
      ..lineTo(w * 0.5, h * 0.94)
      ..close();

    // Dark titanium outline for 100% contrast over any road style
    final borderPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(pinPath, borderPaint);

    // Inner vibrant semantic fill
    final fillPaint = Paint()
      ..color = pinColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(pinPath, fillPaint);

    // Crisp inner core circle
    final corePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, r * 0.72, corePaint);
  }

  @override
  bool shouldRepaint(covariant _DarbMarkerPinPainter oldDelegate) =>
      oldDelegate.pinColor != pinColor || oldDelegate.isConfirmed != isConfirmed;
}

/// Dedicated DARB Zoom-Adaptive Fuel Station Marker
class DarbFuelMarker extends StatelessWidget {
  final FuelStationModel station;
  final double currentZoom;
  final VoidCallback? onTap;

  const DarbFuelMarker({
    super.key,
    required this.station,
    this.currentZoom = 15.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final showDetails = currentZoom >= 14.5;

    return GestureDetector(
      onTap: onTap,
      child: showDetails
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DarbIconColors.emerald, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DarbIcon(
                    DarbIconType.fuel,
                    size: 15,
                    color: DarbIconColors.emerald,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${station.petrolPrice} د.ع',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            )
          : Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                shape: BoxShape.circle,
                border: Border.all(color: DarbIconColors.emerald, width: 1.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: DarbIcon(
                  DarbIconType.fuel,
                  size: 18,
                  color: DarbIconColors.emerald,
                ),
              ),
            ),
    );
  }
}

/// Clean Geometric POI Marker
class DarbPOIMarker extends StatelessWidget {
  final DarbIconType type;
  final String label;
  final Color? color;
  final VoidCallback? onTap;
  final bool showLabel;

  const DarbPOIMarker({
    super.key,
    required this.type,
    required this.label,
    this.color,
    this.onTap,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? DarbIconColors.emerald;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              shape: BoxShape.circle,
              border: Border.all(color: effectiveColor, width: 1.6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: DarbIcon(
                type,
                size: 16,
                color: effectiveColor,
              ),
            ),
          ),
          if (showLabel) ...[
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Text(
                label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
