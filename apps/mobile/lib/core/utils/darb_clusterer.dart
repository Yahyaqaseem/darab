import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

class DarbClusterNode {
  final LatLng position;
  final int count;
  final List<dynamic> items; // references to the original data models

  DarbClusterNode({
    required this.position,
    required this.count,
    required this.items,
  });
}

class DarbMapClusterer {
  /// Clusters a list of items based on zoom level and pixel distance.
  /// Needs the current zoom and map projection bounds for perfect pixel clustering,
  /// but we can approximate it using a simple grid or distance-based approach.
  static List<DarbClusterNode> clusterItems({
    required List<dynamic> items,
    required double Function(dynamic) getLat,
    required double Function(dynamic) getLng,
    required double currentZoom,
    double clusterRadiusPixels = 50.0,
  }) {
    if (items.isEmpty) return [];

    // Simple grid-based clustering approximated for zoom
    // 1 degree at zoom 0 is some number of pixels, we can approximate the grid size in degrees
    // At zoom 15, 1 degree is roughly 2^15 pixels / 360 = 91 pixels.
    final scale = math.pow(2.0, currentZoom);
    
    // Degrees per pixel at this zoom
    final degreesPerPixel = 360.0 / (256.0 * scale);
    final gridDegreeSize = clusterRadiusPixels * degreesPerPixel;

    final List<DarbClusterNode> clusters = [];

    for (final item in items) {
      final lat = getLat(item);
      final lng = getLng(item);
      
      bool clustered = false;
      for (final cluster in clusters) {
        final dLat = (cluster.position.latitude - lat).abs();
        final dLng = (cluster.position.longitude - lng).abs();
        
        if (dLat < gridDegreeSize && dLng < gridDegreeSize) {
          cluster.items.add(item);
          // Optional: recompute centroid
          clustered = true;
          break;
        }
      }
      
      if (!clustered) {
        clusters.add(DarbClusterNode(
          position: LatLng(lat, lng),
          count: 1,
          items: [item],
        ));
      }
    }

    // Update counts
    for (var i = 0; i < clusters.length; i++) {
      final c = clusters[i];
      if (c.items.length > 1) {
        double sumLat = 0;
        double sumLng = 0;
        for (final item in c.items) {
          sumLat += getLat(item);
          sumLng += getLng(item);
        }
        clusters[i] = DarbClusterNode(
          position: LatLng(sumLat / c.items.length, sumLng / c.items.length),
          count: c.items.length,
          items: c.items,
        );
      }
    }

    return clusters;
  }
}
