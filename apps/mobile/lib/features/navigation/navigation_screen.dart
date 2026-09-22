import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/polyline_decoder.dart';
import '../../core/localization/app_strings.dart';
import '../../shared_widgets/darb_location_marker.dart';
import '../../shared_widgets/speed_hud_widget.dart';
import '../../shared_widgets/driver_safe_button.dart';
import '../nidaa_al_tariq/nidaa_dialog.dart';
import '../road_reports/report_dialog.dart';
import '../../core/theme/darb_icons.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import '../../core/theme/darb_vector_theme.dart';
import '../../core/services/darb_tile_cache.dart';
import '../../shared_widgets/waze_pin_widget.dart';

class NavigationScreen extends StatefulWidget {
  final String destinationName;
  final double destLat;
  final double destLng;

  const NavigationScreen({
    super.key,
    required this.destinationName,
    required this.destLat,
    required this.destLng,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  int _selectedRouteIndex = 0;
  bool _isRouteSelecting = true;
  Map<String, dynamic>? _routesData;
  bool _isLoading = true;
  List<LatLng> _routePoints = [];
  Style? _vectorStyle;
  bool _isFollowingUser = true;
  AppState? _appState;
  late final AnimationController _cameraNavController;
  CurvedAnimation? _navCurvedAnimation;
  Tween<double>? _latTween;
  Tween<double>? _lngTween;
  Tween<double>? _zoomTween;
  DateTime _lastCameraMoveTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _cameraNavController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _navCurvedAnimation = CurvedAnimation(
      parent: _cameraNavController,
      curve: Curves.easeOutQuad,
    );
    _cameraNavController.addListener(() {
      if (mounted && _latTween != null && _lngTween != null && _zoomTween != null) {
        _mapController.move(
          LatLng(
            _latTween!.evaluate(_navCurvedAnimation!),
            _lngTween!.evaluate(_navCurvedAnimation!),
          ),
          _zoomTween!.evaluate(_navCurvedAnimation!),
        );
      }
    });

    DarbVectorTheme.loadStyle().then((style) {
      if (mounted) setState(() => _vectorStyle = style);
    });
    _fetchRoutes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = Provider.of<AppState>(context, listen: false);
    if (_appState != state) {
      _appState?.userLocationNotifier.removeListener(_onUserLocationChanged);
      _appState = state;
      _appState?.userLocationNotifier.addListener(_onUserLocationChanged);
    }
  }

  @override
  void dispose() {
    _appState?.userLocationNotifier.removeListener(_onUserLocationChanged);
    _cameraNavController.dispose();
    super.dispose();
  }

  void _onUserLocationChanged() {
    if (!mounted || _isRouteSelecting || !_isFollowingUser || _appState == null) return;

    final userPos = _appState!.userLocationNotifier.value;
    final bearing = _appState!.userHeadingNotifier.value;
    final speed = _appState!.userSpeedNotifier.value;

    final targetPos = _calculateLookahead(userPos, bearing, speed);
    final targetZoom = _calculateDynamicZoom(speed);

    _smoothNavMove(targetPos, targetZoom);
  }

  LatLng _calculateLookahead(LatLng pos, double bearingDeg, double speedKmh) {
    if (speedKmh < 5.0) return pos;
    final lookaheadMeters = (speedKmh * 1.2).clamp(30.0, 100.0);
    final rad = bearingDeg * (math.pi / 180.0);
    final dLat = (lookaheadMeters * math.cos(rad)) / 111139.0;
    final latRad = pos.latitude * (math.pi / 180.0);
    final dLng = (lookaheadMeters * math.sin(rad)) / (111139.0 * math.cos(latRad));
    return LatLng(pos.latitude + dLat, pos.longitude + dLng);
  }

  double _calculateDynamicZoom(double speedKmh) {
    if (speedKmh > 75) return 15.0;
    if (speedKmh > 45) return 15.8;
    if (speedKmh > 20) return 16.4;
    return 17.0;
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final camera = _mapController.camera;
    final latTween = Tween<double>(begin: camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: camera.zoom, end: destZoom);

    final controller = AnimationController(duration: const Duration(milliseconds: 550), vsync: this);
    final animation = CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic);

    controller.addListener(() {
      if (mounted) {
        _mapController.move(
          LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
          zoomTween.evaluate(animation),
        );
      }
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  void _smoothNavMove(LatLng destLocation, double destZoom) {
    if (!mounted) return;

    final now = DateTime.now();
    // Throttle camera updates to at most once per 33ms (30 fps target for camera tweens)
    if (now.difference(_lastCameraMoveTime).inMilliseconds < 33) return;

    final camera = _mapController.camera;
    // Deadband check: if movement is tiny, don't restart tween
    final distMeters = const Distance().as(LengthUnit.Meter, camera.center, destLocation);
    final zoomDiff = (camera.zoom - destZoom).abs();
    if (distMeters < 1.0 && zoomDiff < 0.05) return;

    _lastCameraMoveTime = now;
    _latTween = Tween<double>(begin: camera.center.latitude, end: destLocation.latitude);
    _lngTween = Tween<double>(begin: camera.center.longitude, end: destLocation.longitude);
    _zoomTween = Tween<double>(begin: camera.zoom, end: destZoom);

    _cameraNavController.forward(from: 0.0);
  }

  Future<void> _fetchRoutes() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final userPos = appState.userLocationNotifier.value;
    final originLat = userPos.latitude != 0 ? userPos.latitude : 36.1911;
    final originLng = userPos.longitude != 0 ? userPos.longitude : 44.0091;

    try {
      final data = await appState.apiService.calculateRoutes(
        originLat: originLat,
        originLng: originLng,
        destLat: widget.destLat,
        destLng: widget.destLng,
        destName: widget.destinationName,
      );

      if (mounted) {
        setState(() {
          _routesData = data;
          _isLoading = false;
        });

        // Immediately decode the first route polyline
        final routes = data['routes'] as List? ?? [];
        if (routes.isNotEmpty) {
          final firstRoute = routes[0];
          final geom = firstRoute['geometry'] as String?;
          if (geom != null) {
            final points = PolylineDecoder.decode(geom);
            setState(() {
              _routePoints = points;
            });
            if (points.isNotEmpty) {
              try {
                final bounds = LatLngBounds.fromPoints(points);
                _mapController.fitCamera(
                  CameraFit.bounds(
                    bounds: bounds,
                    padding: const EdgeInsets.only(top: 100, bottom: 260, left: 40, right: 40),
                  ),
                );
              } catch (_) {}

              if (DarbVectorTheme.cachingTileProvider != null) {
                DarbTilePrefetcher.prefetchRoute(
                  routePoints: points,
                  provider: DarbVectorTheme.cachingTileProvider!,
                );
              }
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startDrive() {
    setState(() {
      _isRouteSelecting = false;
      _isFollowingUser = true;
    });
    final routes = _routesData?['routes'] as List? ?? [];
    if (routes.isNotEmpty) {
      final selected = routes[_selectedRouteIndex];
      final geom = selected['geometry'] as String?;
      if (geom != null) {
        setState(() {
          _routePoints = PolylineDecoder.decode(geom);
        });
      }
      final appState = Provider.of<AppState>(context, listen: false);
      appState.selectRoutePreview(selected, widget.destinationName, widget.destLat, widget.destLng);
      appState.startNavigation();

      if (DarbVectorTheme.cachingTileProvider != null && _routePoints.isNotEmpty) {
        DarbTilePrefetcher.prefetchRoute(
          routePoints: _routePoints,
          provider: DarbVectorTheme.cachingTileProvider!,
        );
      }

      final originLat = appState.currentLat != 0 ? appState.currentLat : 36.1911;
      final originLng = appState.currentLng != 0 ? appState.currentLng : 44.0091;
      _animatedMapMove(LatLng(originLat, originLng), 16.5);
    }
  }

  Future<void> _finishTrip() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final lang = appState.currentLanguage;

    if (appState.tripState == TripState.NAVIGATING) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(AppStrings.tr('end_trip', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            lang == 'en'
                ? 'You have not reached your destination yet. Are you sure you want to end this trip?'
                : (lang == 'ku'
                    ? 'هێشتا نەگەیشتوویتە جێگای مەبەست. ئایا دڵنیایت دەتەوێت کۆتایی بە گەشتەکە بهێنیت؟'
                    : 'أنت لم تصل إلى وجهتك بعد. هل أنت متأكد من رغبتك في إنهاء الرحلة؟'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppStrings.tr('cancel', lang), style: const TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AppStrings.tr('end_trip', lang), style: const TextStyle(color: AppTheme.alertRed, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
      appState.setTripState(TripState.CANCELLED);
    }

    appState.stopNavigation();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = appState.currentLanguage;
    final routes = _routesData?['routes'] as List? ?? [];
    final currentRoute = routes.isNotEmpty ? routes[_selectedRouteIndex.clamp(0, routes.length - 1)] : null;

    final userPos = appState.userLocationNotifier.value;
    final userLat = userPos.latitude != 0 ? userPos.latitude : 36.1911;
    final userLng = userPos.longitude != 0 ? userPos.longitude : 44.0091;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: Stack(
        children: [
          // LAYER 1: Full-Screen Live Map (ALWAYS VISIBLE!)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(userLat, userLng),
              initialZoom: 15.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.drag |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.flingAnimation,
              ),
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture) {
                  DarbTilePrefetcher.pausePrefetch();
                  if (_isFollowingUser) {
                    setState(() => _isFollowingUser = false);
                  }
                } else {
                  DarbTilePrefetcher.resumePrefetch();
                }
              },
            ),
            children: [
              if (_vectorStyle != null)
                RepaintBoundary(
                  child: VectorTileLayer(
                    theme: _vectorStyle!.theme,
                    sprites: _vectorStyle!.sprites,
                    tileProviders: _vectorStyle!.providers,
                    layerMode: VectorTileLayerMode.vector,
                    memoryTileCacheMaxSize: 128 * 1024 * 1024,
                    memoryTileDataCacheMaxSize: 500,
                    fileCacheMaximumSizeInBytes: 256 * 1024 * 1024,
                    maximumTileSubstitutionDifference: 3,
                    textCacheMaxSize: 1000,
                    concurrency: 4,
                    cacheFolder: DarbCachingTileProvider.getCacheDirectory,
                  ),
                )
              else
                RepaintBoundary(
                  child: TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.darb.iraq',
                    tileBuilder: isDark
                        ? (context, tileWidget, tile) {
                            return ColorFiltered(
                              colorFilter: const ColorFilter.matrix(<double>[
                                -0.8, 0, 0, 0, 210,
                                0, -0.8, 0, 0, 210,
                                0, 0, -0.8, 0, 220,
                                0, 0, 0, 1, 0,
                              ]),
                              child: tileWidget,
                            );
                          }
                        : null,
                  ),
                ),
              // Route Polyline (Waze Vibrant High-Contrast Green Path)
              if (_routePoints.isNotEmpty)
                RepaintBoundary(
                  child: PolylineLayer(
                    polylines: [
                      // Polyline dark casing / shadow for maximum contrast
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 8.5,
                        color: const Color(0xFF042F2E),
                      ),
                      // Polyline vibrant green core
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 5.5,
                        color: const Color(0xFF10B981),
                      ),
                    ],
                  ),
                ),
              // Static & Semi-Static Markers: Road Incidents & Destination Pin
              RepaintBoundary(
                child: MarkerLayer(
                  markers: [
                    ...appState.reports.map((r) => Marker(
                      point: LatLng(r.latitude, r.longitude),
                      width: 38,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: WazePinWidget(report: r, size: 36),
                    )),
                    Marker(
                      point: LatLng(widget.destLat, widget.destLng),
                      width: 38,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: const DarbPOIMarker(
                        type: DarbIconType.recenter,
                        label: '',
                        color: DarbIconColors.criticalRed,
                      ),
                    ),
                  ],
                ),
              ),
              // Dynamic User Location Marker (Isolated with ValueListenableBuilder)
              ValueListenableBuilder<LatLng>(
                valueListenable: appState.userLocationNotifier,
                builder: (context, currentLoc, _) {
                  return MarkerLayer(
                    markers: [
                      Marker(
                        point: currentLoc,
                        width: 72,
                        height: 72,
                        alignment: Alignment.center,
                        child: RepaintBoundary(
                          child: ValueListenableBuilder<double>(
                            valueListenable: appState.userHeadingNotifier,
                            builder: (context, heading, _) {
                              return ValueListenableBuilder<double>(
                                valueListenable: appState.userSpeedNotifier,
                                builder: (context, speed, _) {
                                  return DarbLocationMarker(
                                    position: currentLoc,
                                    bearing: speed > 2 ? heading : 0.0,
                                    speedKmh: speed,
                                    accuracyMeters: 6.0,
                                    size: 48,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),

          // Recenter Floating Button (Shown when user moves map)
          if (!_isFollowingUser)
            Positioned(
              left: 16,
              bottom: 230,
              child: RepaintBoundary(
                child: GestureDetector(
                  onTap: () {
                    final currentLoc = appState.userLocationNotifier.value;
                    final currentSpeed = appState.userSpeedNotifier.value;
                    final currentHeading = appState.userHeadingNotifier.value;
                    final targetPos = _calculateLookahead(
                      currentLoc,
                      currentHeading,
                      currentSpeed,
                    );
                    final targetZoom = _isRouteSelecting ? 15.0 : _calculateDynamicZoom(currentSpeed);
                    _animatedMapMove(targetPos, targetZoom);
                    setState(() => _isFollowingUser = true);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: (isDark ? const Color(0xFF0F172A) : Colors.white).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3))],
                      border: Border.all(color: DarbIconColors.emerald, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const DarbIcon(DarbIconType.recenter, color: DarbIconColors.emerald, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.tr('recenter', lang),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: DarbIconColors.emerald),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // LAYER 2: Top Glass Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: RepaintBoundary(
                child: Row(
                  children: [
                    // Back button
                    DarbIconButton(
                      icon: DarbIconType.back,
                      size: 44,
                      onTap: _finishTrip,
                    ),
                    const SizedBox(width: 12),
                    // Destination banner
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: (isDark ? AppTheme.darkCard : Colors.white).withOpacity(0.92),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                        ),
                        child: Row(
                          children: [
                            DarbIcon(
                              _isRouteSelecting ? DarbIconType.route : DarbIconType.recenter,
                              color: DarbIconColors.emerald,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.destinationName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // LAYER 3: Driving Mode HUD overlays
          if (!_isRouteSelecting) ...[
            // Speed HUD (Top Left)
            Positioned(
              left: 16,
              top: 100,
              child: RepaintBoundary(
                child: ValueListenableBuilder<double>(
                  valueListenable: appState.userSpeedNotifier,
                  builder: (context, speed, _) {
                    return SpeedHudWidget(currentSpeedKmh: speed);
                  },
                ),
              ),
            ),
            // Right Side Driving Actions (Warning & SOS)
            Positioned(
              right: 16,
              top: 100,
              child: RepaintBoundary(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DarbIconButton(
                      icon: DarbIconType.quickReport,
                      iconColor: DarbIconColors.warningOrange,
                      borderColor: DarbIconColors.warningOrange.withOpacity(0.4),
                      onTap: () {
                        showDialog(context: context, builder: (_) => const ReportDialog());
                      },
                    ),
                    const SizedBox(height: 12),
                    DarbSOSButton(
                      size: 44,
                      onTap: () {
                        showDialog(context: context, builder: (_) => const NidaaDialog());
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],

          // LAYER 4: Bottom Panel (Waze-style card!)
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: RepaintBoundary(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: (isDark ? AppTheme.darkCard : Colors.white).withOpacity(0.96),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.primaryEmerald)),
                            const SizedBox(width: 16),
                            Text(
                              lang == 'en' ? 'Calculating best route...' : (lang == 'ku' ? 'خەریکی دۆزینەوەی باشترین ڕێگایە...' : 'جارِ حساب أفضل مسار...'),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      : Selector<AppState, Map<String, dynamic>?>(
                          selector: (_, s) => s.activeRoute,
                          builder: (context, activeRoute, _) {
                            final routeToDisplay = activeRoute ?? currentRoute;
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Route Metrics Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildMetric(
                                      routeToDisplay?['durationFormatted'] ?? '15 دقيقة',
                                      AppStrings.tr('duration', lang),
                                      AppTheme.primaryEmerald,
                                    ),
                                    Container(width: 1, height: 36, color: Colors.grey.withOpacity(0.2)),
                                    _buildMetric(
                                      '${routeToDisplay?['distanceKm'] ?? 5.2} كم',
                                      AppStrings.tr('distance', lang),
                                      isDark ? Colors.white : Colors.black87,
                                    ),
                                    Container(width: 1, height: 36, color: Colors.grey.withOpacity(0.2)),
                                    _buildMetric(
                                      routeToDisplay?['eta'] ?? '09:20',
                                      AppStrings.tr('eta', lang),
                                      isDark ? Colors.white70 : Colors.black54,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Big Action Button
                                if (_isRouteSelecting)
                                  DriverSafeButton(
                                    label: AppStrings.tr('start_navigation', lang),
                                    icon: Icons.navigation_rounded,
                                    onPressed: _startDrive,
                                  )
                                else
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.alertRed,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(double.infinity, 50),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    icon: const Icon(Icons.close_rounded),
                                    label: Text(
                                      AppStrings.tr('end_trip', lang),
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: _finishTrip,
                                  ),
                              ],
                            );
                          },
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
