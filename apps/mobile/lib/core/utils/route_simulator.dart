import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class RouteSimulator {
  final List<LatLng> routePoints;
  final double speedKmh;
  final Function(LatLng location, double bearing, double speed) onUpdate;
  final VoidCallback onFinish;
  
  Timer? _timer;
  int _currentIndex = 0;
  double _distanceToNextPoint = 0.0;
  
  // 60 frames per second update rate
  static const int _updateIntervalMs = 16; 

  RouteSimulator({
    required this.routePoints,
    required this.speedKmh,
    required this.onUpdate,
    required this.onFinish,
  });

  void start() {
    if (routePoints.isEmpty) return;
    _currentIndex = 0;
    _distanceToNextPoint = 0.0;
    
    _timer = Timer.periodic(const Duration(milliseconds: _updateIntervalMs), (timer) {
      if (_currentIndex >= routePoints.length - 1) {
        stop();
        onFinish();
        return;
      }
      
      final currentPt = routePoints[_currentIndex];
      final nextPt = routePoints[_currentIndex + 1];
      
      final distMeters = _calculateDistance(currentPt, nextPt);
      
      // Speed in meters per frame
      final speedMps = speedKmh * (1000.0 / 3600.0);
      final distancePerFrame = speedMps * (_updateIntervalMs / 1000.0);
      
      _distanceToNextPoint += distancePerFrame;
      
      if (_distanceToNextPoint >= distMeters) {
        _currentIndex++;
        _distanceToNextPoint = 0.0; // reset
        // Ensure we don't overshoot bounds next frame
        if (_currentIndex >= routePoints.length - 1) {
          stop();
          onFinish();
          return;
        }
      } else {
        // Interpolate
        final fraction = distMeters > 0 ? _distanceToNextPoint / distMeters : 0.0;
        final interLat = currentPt.latitude + (nextPt.latitude - currentPt.latitude) * fraction;
        final interLng = currentPt.longitude + (nextPt.longitude - currentPt.longitude) * fraction;
        final bearing = _calculateBearing(currentPt, nextPt);
        
        onUpdate(LatLng(interLat, interLng), bearing, speedKmh);
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  double _calculateDistance(LatLng pt1, LatLng pt2) {
    const R = 6371e3; // metres
    final lat1 = pt1.latitude * math.pi / 180;
    final lat2 = pt2.latitude * math.pi / 180;
    final deltaLat = (pt2.latitude - pt1.latitude) * math.pi / 180;
    final deltaLng = (pt2.longitude - pt1.longitude) * math.pi / 180;

    final a = math.sin(deltaLat/2) * math.sin(deltaLat/2) +
              math.cos(lat1) * math.cos(lat2) *
              math.sin(deltaLng/2) * math.sin(deltaLng/2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a));
    return R * c;
  }

  double _calculateBearing(LatLng pt1, LatLng pt2) {
    final lat1 = pt1.latitude * math.pi / 180;
    final lng1 = pt1.longitude * math.pi / 180;
    final lat2 = pt2.latitude * math.pi / 180;
    final lng2 = pt2.longitude * math.pi / 180;

    final y = math.sin(lng2 - lng1) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
              math.sin(lat1) * math.cos(lat2) * math.cos(lng2 - lng1);
    final bearing = (math.atan2(y, x) * 180 / math.pi + 360) % 360;
    return bearing;
  }
}
