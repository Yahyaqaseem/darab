import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../core/models/models.dart';
import '../core/providers/app_state.dart';
import '../core/theme/darb_icons.dart';
import '../../features/fuel/fuel_screen.dart';

/// High-Performance Viewport-Culled and Clustered Marker Layer
/// 
/// Solves zoom and pan jank:
/// 1. Viewport Culling: Drops any marker outside the visible camera bounds + 15% margin.
/// 2. Zoom-Level Gating: Low zoom (<11) shows only critical accidents/closures.
/// 3. Spatial Clustering: Medium zoom (11-13) groups nearby incidents into cluster badges.
/// 4. High zoom (13+) shows full detail fuel stations and incident pins.
/// 5. Zero full-screen rebuilds on zoom.
class DarbOptimizedMarkerLayer extends StatelessWidget {
  final void Function(Widget screen, bool isDark)? onOpenSheet;
  final void Function(String name, double lat, double lng)? onNavigateTo;

  const DarbOptimizedMarkerLayer({
    super.key,
    this.onOpenSheet,
    this.onNavigateTo,
  });

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final zoom = camera.zoom;
    final bounds = camera.visibleBounds;

    // Viewport bounding box with 15% safety buffer to eliminate edge pop-in
    final latSpan = (bounds.north - bounds.south).abs();
    final lngSpan = (bounds.east - bounds.west).abs();
    final padLat = latSpan * 0.15;
    final padLng = lngSpan * 0.15;
    final minLat = min(bounds.south, bounds.north) - padLat;
    final maxLat = max(bounds.south, bounds.north) + padLat;
    final minLng = min(bounds.west, bounds.east) - padLng;
    final maxLng = max(bounds.west, bounds.east) + padLng;

    return Consumer<AppState>(
      builder: (context, appState, _) {
        final markers = <Marker>[];

        // 1. Process Road Reports with Viewport Culling & Adaptive Clustering
        final visibleReports = appState.reports.where((r) {
          return r.latitude >= minLat &&
              r.latitude <= maxLat &&
              r.longitude >= minLng &&
              r.longitude <= maxLng;
        }).toList(growable: false);

        if (zoom < 11.0) {
          // Low Zoom: Only show critical blockers (Accidents & Closures)
          for (final r in visibleReports) {
            final t = r.type.toUpperCase();
            if (t.contains('ACCIDENT') || t.contains('CLOSURE')) {
              markers.add(Marker(
                key: ValueKey('rep_${r.id}'),
                point: LatLng(r.latitude, r.longitude),
                width: 36,
                height: 42,
                alignment: Alignment.topCenter,
                child: DarbReportMarker(report: r, size: 32),
              ));
            }
          }
        } else if (zoom < 13.0) {
          // Medium Zoom: Spatial grid clustering (~400m cell size)
          final gridSize = 0.004; // roughly 400 meters
          final clusters = <String, List<RoadReportModel>>{};

          for (final r in visibleReports) {
            final cellX = (r.longitude / gridSize).floor();
            final cellY = (r.latitude / gridSize).floor();
            final cellKey = '${cellX}_$cellY';
            (clusters[cellKey] ??= []).add(r);
          }

          clusters.forEach((cellKey, clusterReports) {
            if (clusterReports.length == 1) {
              final r = clusterReports.first;
              markers.add(Marker(
                key: ValueKey('rep_${r.id}'),
                point: LatLng(r.latitude, r.longitude),
                width: 38,
                height: 44,
                alignment: Alignment.topCenter,
                child: DarbReportMarker(report: r, size: 36),
              ));
            } else {
              // Compute center of cluster
              double avgLat = 0;
              double avgLng = 0;
              for (final r in clusterReports) {
                avgLat += r.latitude;
                avgLng += r.longitude;
              }
              avgLat /= clusterReports.length;
              avgLng /= clusterReports.length;

              markers.add(Marker(
                key: ValueKey('cluster_$cellKey'),
                point: LatLng(avgLat, avgLng),
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: DarbClusterMarker(
                  count: clusterReports.length,
                ),
              ));
            }
          });
        } else {
          // High Zoom (13+): Show all visible individual reports
          for (final r in visibleReports) {
            markers.add(Marker(
              key: ValueKey('rep_${r.id}'),
              point: LatLng(r.latitude, r.longitude),
              width: 38,
              height: 44,
              alignment: Alignment.topCenter,
              child: DarbReportMarker(report: r, size: 36),
            ));
          }
        }

        // 2. Process Fuel Stations (Only visible when zoom >= 12.5)
        if (zoom >= 12.5) {
          final isPill = zoom >= 14.5;
          for (final s in appState.fuelStations) {
            if (s.latitude >= minLat &&
                s.latitude <= maxLat &&
                s.longitude >= minLng &&
                s.longitude <= maxLng) {
              markers.add(Marker(
                key: ValueKey('fuel_${s.id}'),
                point: LatLng(s.latitude, s.longitude),
                width: isPill ? 90 : 36,
                height: 36,
                alignment: Alignment.center,
                child: DarbFuelMarker(
                  station: s,
                  currentZoom: zoom,
                  onTap: () {
                    if (onOpenSheet != null) {
                      onOpenSheet!(const FuelScreen(), isDark);
                    }
                  },
                ),
              ));
            }
          }
        }

        // 3. Landmarks (Erbil Citadel & Family Mall) with Viewport Culling
        const citadelPos = LatLng(36.1911, 44.0094);
        if (citadelPos.latitude >= minLat &&
            citadelPos.latitude <= maxLat &&
            citadelPos.longitude >= minLng &&
            citadelPos.longitude <= maxLng) {
          markers.add(Marker(
            key: const ValueKey('landmark_citadel'),
            point: citadelPos,
            width: 40,
            height: 48,
            alignment: Alignment.topCenter,
            child: DarbPOIMarker(
              type: DarbIconType.civic,
              label: 'قلعة أربيل',
              showLabel: zoom >= 14.0,
              onTap: () => onNavigateTo?.call('قلعة أربيل', 36.1911, 44.0094),
            ),
          ));
        }

        const mallPos = LatLng(36.2089, 44.0092);
        if (mallPos.latitude >= minLat &&
            mallPos.latitude <= maxLat &&
            mallPos.longitude >= minLng &&
            mallPos.longitude <= maxLng) {
          markers.add(Marker(
            key: const ValueKey('landmark_mall'),
            point: mallPos,
            width: 40,
            height: 48,
            alignment: Alignment.topCenter,
            child: DarbPOIMarker(
              type: DarbIconType.store,
              label: 'فاميلي مول',
              color: DarbIconColors.checkpointBlue,
              showLabel: zoom >= 14.0,
              onTap: () => onNavigateTo?.call('فاميلي مول', 36.2089, 44.0092),
            ),
          ));
        }

        return RepaintBoundary(
          child: MarkerLayer(markers: markers),
        );
      },
    );
  }
}

/// Compact Visual Cluster Badge for multiple nearby reports
class DarbClusterMarker extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const DarbClusterMarker({
    super.key,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          shape: BoxShape.circle,
          border: Border.all(color: DarbIconColors.warningOrange, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DarbIcon(DarbIconType.danger, size: 12, color: DarbIconColors.warningOrange),
              const SizedBox(width: 2),
              Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
