import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

/// DARB Production-Grade Vector Tile Cache & Prefetch Engine
/// 
/// 3-Tier Architecture:
/// - L1: Instant RAM LRU Cache (Up to 600 tiles in memory, < 0.1ms access)
/// - L2: Persistent Disk Cache (Survives app restarts & device reboots)
/// - L3: Resilient Network with In-Flight Deduplication & Concurrency Throttling
class DarbCachingTileProvider extends VectorTileProvider {
  final String urlTemplate;
  @override
  final int maximumZoom;
  @override
  final int minimumZoom;

  // L1 Memory Cache (LRU)
  static final Map<String, Uint8List> _l1Cache = {};
  static final List<String> _l1Order = [];
  static const int _maxL1Tiles = 600;

  // In-Flight Request Deduplication (prevents duplicate simultaneous network calls)
  static final Map<String, Future<Uint8List>> _inFlight = {};

  // Persistent storage directory
  static Directory? _diskCacheDir;
  static bool _isInit = false;

  DarbCachingTileProvider({
    required this.urlTemplate,
    this.maximumZoom = 14,
    this.minimumZoom = 0,
  }) {
    _initDiskCache();
  }

  static Future<Directory> getCacheDirectory() async {
    if (_diskCacheDir != null) return _diskCacheDir!;
    try {
      final docs = await getApplicationDocumentsDirectory();
      _diskCacheDir = Directory("${docs.path}/darb_vector_tiles_cache");
      if (!await _diskCacheDir!.exists()) {
        await _diskCacheDir!.create(recursive: true);
      }
    } catch (e) {
      debugPrint('[DarbTileCache] Error getting docs dir: $e, using temp fallback');
      final temp = await getTemporaryDirectory();
      _diskCacheDir = Directory("${temp.path}/darb_vector_tiles_cache");
      if (!await _diskCacheDir!.exists()) {
        await _diskCacheDir!.create(recursive: true);
      }
    }
    _isInit = true;
    return _diskCacheDir!;
  }

  static Future<void> _initDiskCache() async {
    if (!_isInit) {
      await getCacheDirectory();
    }
  }

  @override
  Future<Uint8List> provide(TileIdentity tile) async {
    final key = "${tile.z}_${tile.x}_${tile.y}";

    // 1. TIER 1: Check In-Memory RAM Cache (Instant 0ms)
    final mem = _l1Cache[key];
    if (mem != null) {
      _touchL1(key);
      return mem;
    }

    // 2. TIER 2: Check Persistent Disk Cache (Fast 1-2ms)
    final dir = await getCacheDirectory();
    final file = File("${dir.path}/$key.pbf");
    if (await file.exists()) {
      try {
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) {
          _putL1(key, bytes);
          return bytes;
        }
      } catch (e) {
        debugPrint("[DarbTileCache] Disk read error for $key: $e");
      }
    }

    // 3. TIER 3: Check In-Flight Deduplication (Reuse pending network request)
    if (_inFlight.containsKey(key)) {
      return _inFlight[key]!;
    }

    // 4. Download from Network with In-Flight registration
    final future = _downloadAndCacheTile(tile, key, file);
    _inFlight[key] = future;

    try {
      final result = await future;
      return result;
    } finally {
      _inFlight.remove(key);
    }
  }

  Future<Uint8List> _downloadAndCacheTile(TileIdentity tile, String key, File diskFile) async {
    final url = urlTemplate
        .replaceAll('{z}', tile.z.toString())
        .replaceAll('{x}', tile.x.toString())
        .replaceAll('{y}', tile.y.toString());

    try {
      final uri = Uri.parse(url);
      final resp = await http.get(
        uri,
        headers: {
          'User-Agent': 'DARB-Iraq/1.0',
          'Accept': 'application/x-protobuf, */*',
        },
      ).timeout(const Duration(seconds: 7));

      if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
        final bytes = resp.bodyBytes;
        // Save to L1 RAM
        _putL1(key, bytes);

        // Save to L2 Disk asynchronously (do not block render)
        diskFile.writeAsBytes(bytes).catchError((err) {
          debugPrint("[DarbTileCache] Failed to write disk tile $key: $err");
          return diskFile;
        });

        return bytes;
      }
    } catch (e) {
      debugPrint("[DarbTileCache] Network error fetching $key: $e");
    }

    // Offline Resilience: if network failed, check if file exists anyway
    if (await diskFile.exists()) {
      try {
        return await diskFile.readAsBytes();
      } catch (_) {}
    }

    // Return minimal valid empty vector tile bytes so renderer doesn't crash or freeze
    return Uint8List(0);
  }

  static void _putL1(String key, Uint8List data) {
    if (_l1Cache.length >= _maxL1Tiles) {
      final oldest = _l1Order.removeAt(0);
      _l1Cache.remove(oldest);
    }
    _l1Cache[key] = data;
    _l1Order.remove(key);
    _l1Order.add(key);
  }

  static void _touchL1(String key) {
    _l1Order.remove(key);
    _l1Order.add(key);
  }
}

/// Background Intelligent Tile Prefetcher
/// 
/// Prefetches tiles around current driver location and along active navigation route
class DarbTilePrefetcher {
  static final Set<String> _prefetchedKeys = {};
  static bool _isPrefetchingRoute = false;

  /// Prefetches a grid of tiles around a center coordinate (Viewport buffer)
  static Future<void> prefetchAround({
    required LatLng center,
    required double zoom,
    int radius = 1,
    required DarbCachingTileProvider provider,
  }) async {
    final z = zoom.round().clamp(provider.minimumZoom, provider.maximumZoom);
    final centerTile = _latLngToTile(center, z);

    for (int dx = -radius; dx <= radius; dx++) {
      for (int dy = -radius; dy <= radius; dy++) {
        final tx = centerTile.x + dx;
        final ty = centerTile.y + dy;
        final key = "${z}_${tx}_${ty}";

        if (!_prefetchedKeys.contains(key)) {
          _prefetchedKeys.add(key);
          final tileId = TileIdentity(z, tx, ty);
          if (tileId.isValid()) {
            unawaited(provider.provide(tileId).catchError((_) => Uint8List(0)));
          }
        }
      }
    }
  }

  /// Prefetches the road corridor along an active navigation route
  static Future<void> prefetchRoute({
    required List<LatLng> routePoints,
    required DarbCachingTileProvider provider,
  }) async {
    if (routePoints.isEmpty || _isPrefetchingRoute) return;
    _isPrefetchingRoute = true;

    try {
      for (final z in [13, 14]) {
        if (z > provider.maximumZoom) continue;

        final routeTiles = <Point<int>>{};
        final step = max(1, (routePoints.length / 40).ceil());
        for (int i = 0; i < routePoints.length; i += step) {
          final pt = routePoints[i];
          final t = _latLngToTile(pt, z);
          routeTiles.add(t);
          routeTiles.add(Point(t.x + 1, t.y));
          routeTiles.add(Point(t.x - 1, t.y));
          routeTiles.add(Point(t.x, t.y + 1));
          routeTiles.add(Point(t.x, t.y - 1));
        }

        for (final t in routeTiles) {
          final key = "${z}_${t.x}_${t.y}";
          if (!_prefetchedKeys.contains(key)) {
            _prefetchedKeys.add(key);
            final tileId = TileIdentity(z, t.x, t.y);
            if (tileId.isValid()) {
              await provider.provide(tileId).catchError((_) => Uint8List(0));
              await Future.delayed(const Duration(milliseconds: 20));
            }
          }
        }
      }
    } catch (e) {
      debugPrint("[DarbTilePrefetcher] Error during route prefetch: $e");
    } finally {
      _isPrefetchingRoute = false;
    }
  }

  static Point<int> _latLngToTile(LatLng loc, int zoom) {
    final n = 1 << zoom;
    final x = ((loc.longitude + 180.0) / 360.0 * n).floor().clamp(0, n - 1);
    final latRad = loc.latitude * pi / 180.0;
    final y = ((1.0 - (log(tan(latRad) + 1.0 / cos(latRad)) / pi)) / 2.0 * n).floor().clamp(0, n - 1);
    return Point(x, y);
  }
}
