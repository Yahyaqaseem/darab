import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/polyline_decoder.dart';
import '../../core/localization/app_strings.dart';
import '../../shared_widgets/nav_cursor.dart';
import '../../shared_widgets/speed_hud_widget.dart';
import '../../shared_widgets/driver_safe_button.dart';
import '../nidaa_al_tariq/nidaa_dialog.dart';
import '../road_reports/report_dialog.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import '../../core/theme/darb_vector_theme.dart';

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

class _NavigationScreenState extends State<NavigationScreen> {
  final MapController _mapController = MapController();
  int _selectedRouteIndex = 0;
  bool _isRouteSelecting = true;
  Map<String, dynamic>? _routesData;
  bool _isLoading = true;
  List<LatLng> _routePoints = [];
  Style? _vectorStyle;

  @override
  void initState() {
    super.initState();
    DarbVectorTheme.loadStyle().then((style) {
      if (mounted) setState(() => _vectorStyle = style);
    });
    _fetchRoutes();
  }

  Future<void> _fetchRoutes() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final originLat = appState.currentLat != 0 ? appState.currentLat : 36.1911;
    final originLng = appState.currentLng != 0 ? appState.currentLng : 44.0091;

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
            setState(() {
              _routePoints = PolylineDecoder.decode(geom);
            });
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
    setState(() => _isRouteSelecting = false);
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
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = appState.currentLanguage;
    final routes = _routesData?['routes'] as List? ?? [];
    final currentRoute = routes.isNotEmpty ? routes[_selectedRouteIndex.clamp(0, routes.length - 1)] : null;

    final userLat = appState.currentLat != 0 ? appState.currentLat : 36.1911;
    final userLng = appState.currentLng != 0 ? appState.currentLng : 44.0091;

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
            ),
            children: [
              if (_vectorStyle != null)
                VectorTileLayer(
                  theme: _vectorStyle!.theme,
                  sprites: _vectorStyle!.sprites,
                  tileProviders: _vectorStyle!.providers,
                  layerMode: VectorTileLayerMode.raster,
                )
              else
                TileLayer(
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
              // Route Polyline (Green glowing path with border)
              if (_routePoints.isNotEmpty) ...[
                PolylineLayer(
                  polylines: [
                    // Polyline casing / shadow
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 8.0,
                      color: const Color(0xFF065F46),
                    ),
                    // Polyline bright green core
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.0,
                      color: AppTheme.primaryEmerald,
                    ),
                  ],
                ),
              ],
              MarkerLayer(
                markers: [
                  // User Location (Waze 3D cyan navigation cursor!)
                  Marker(
                    point: LatLng(userLat, userLng),
                    width: 50,
                    height: 50,
                    child: const NavCursorWidget(size: 46),
                  ),
                  // Destination Pin
                  Marker(
                    point: LatLng(widget.destLat, widget.destLng),
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.location_on_rounded, color: AppTheme.alertRed, size: 44),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // LAYER 2: Top Glass Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: _finishTrip,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (isDark ? AppTheme.darkCard : Colors.white).withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    ),
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
                          Icon(
                            _isRouteSelecting ? Icons.route_rounded : Icons.navigation_rounded,
                            color: AppTheme.primaryEmerald,
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

          // LAYER 3: Driving Mode HUD overlays
          if (!_isRouteSelecting) ...[
            // Speed HUD (Top Left)
            Positioned(
              left: 16,
              top: 100,
              child: SpeedHudWidget(currentSpeedKmh: appState.currentSpeedKmh),
            ),
            // Right Side Driving Actions (Warning & SOS)
            Positioned(
              right: 16,
              top: 100,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCircleBtn(Icons.warning_rounded, AppTheme.accentOrange, () {
                    showDialog(context: context, builder: (_) => const ReportDialog());
                  }, isDark),
                  const SizedBox(height: 12),
                  _buildCircleBtn(Icons.sos_rounded, AppTheme.alertRed, () {
                    showDialog(context: context, builder: (_) => const NidaaDialog());
                  }, isDark),
                ],
              ),
            ),
          ],

          // LAYER 4: Bottom Panel (Waze-style card!)
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
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
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Route Metrics Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMetric(
                                currentRoute?['durationFormatted'] ?? '15 دقيقة',
                                AppStrings.tr('duration', lang),
                                AppTheme.primaryEmerald,
                              ),
                              Container(width: 1, height: 36, color: Colors.grey.withOpacity(0.2)),
                              _buildMetric(
                                '${currentRoute?['distanceKm'] ?? 5.2} كم',
                                AppStrings.tr('distance', lang),
                                isDark ? Colors.white : Colors.black87,
                              ),
                              Container(width: 1, height: 36, color: Colors.grey.withOpacity(0.2)),
                              _buildMetric(
                                currentRoute?['eta'] ?? '09:20',
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

  Widget _buildCircleBtn(IconData icon, Color color, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: (isDark ? AppTheme.darkCard : Colors.white).withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
