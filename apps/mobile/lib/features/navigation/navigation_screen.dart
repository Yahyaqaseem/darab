import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/utils/polyline_decoder.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../shared_widgets/speed_hud_widget.dart';
import '../../shared_widgets/driver_safe_button.dart';
import '../nidaa_al_tariq/nidaa_dialog.dart';
import '../road_reports/report_dialog.dart';
import '../trips/trip_summary_screen.dart';

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
  int _selectedRouteIndex = 0;
  bool _isRouteSelecting = true;
  Map<String, dynamic>? _routesData;
  bool _isLoading = true;
  List<LatLng> _routePoints = [];

  // Driving Simulation Timers
  
  
  int _secondsElapsed = 0;
  double _distanceTraveledKm = 0.0;
  final List<double> _speedLog = [70, 75, 74, 80, 82, 250, 78, 85]; // Included 250 GPS spike for anomaly test

  @override
  void initState() {
    super.initState();
    _fetchRoutes();
  }

  @override
  void dispose() {
    
    super.dispose();
  }

  Future<void> _fetchRoutes() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final data = await appState.apiService.calculateRoutes(
      originLat: appState.currentLat,
      originLng: appState.currentLng,
      destLat: widget.destLat,
      destLng: widget.destLng,
      destName: widget.destinationName,
    );

    setState(() {
      _routesData = data;
      _isLoading = false;
    });
  }

  void _startDrive() {
    setState(() => _isRouteSelecting = false);
    final routes = _routesData?['routes'] as List?;
    if (routes != null && routes.isNotEmpty) {
      final selected = routes[_selectedRouteIndex];
      String? geom = selected['geometry'];
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
    
    // Only ask if not already completed/arriving automatically
    if (appState.tripState == TripState.NAVIGATING) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('إنهاء الرحلة؟', style: TextStyle()),
          content: const Text('أنت لم تصل إلى وجهتك بعد. هل أنت متأكد من رغبتك في إنهاء الرحلة؟', style: TextStyle()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle( color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('نعم، إنهاء', style: TextStyle( color: Colors.red)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
      appState.setTripState(TripState.CANCELLED);
    }
    
    appState.stopNavigation();
    Navigator.pop(context); // Just pop back to Home map
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.destinationName)),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'جارِ تحليل بيانات الطرق الحية وحساب أفضل المسارات...',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    final routes = _routesData?['routes'] as List? ?? [];

    if (_isRouteSelecting) {
      return Scaffold(
        appBar: AppBar(
          title: Text('اختيار المسار إلى ${widget.destinationName}'),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: routes.length,
                itemBuilder: (ctx, idx) {
                  final r = routes[idx];
                  final isSelected = _selectedRouteIndex == idx;
                  final isRecommended = r['isRecommended'] == true;
                  final warnings = (r['incidentsSummary']?['warnings'] as List?) ?? [];

                  return GestureDetector(
                    onTap: () => setState(() => _selectedRouteIndex = idx),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryEmerald : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                r['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              if (isRecommended)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryEmerald.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    '⭐ المسار الموصى به',
                                    style: TextStyle(
                                      color: AppTheme.primaryEmerald,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                r['durationFormatted'],
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                '${r['distanceKm']} كم',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
                                  
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'الوصول: ${r['eta']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.primaryEmerald),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    r['recommendationReason'],
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (warnings.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ...warnings.map(
                              (w) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(w.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -4)),
                ],
              ),
              child: DriverSafeButton(
                label: 'ابدأ الملاحة الآن',
                icon: Icons.navigation_rounded,
                onPressed: _startDrive,
              ),
            ),
          ],
        ),
      );
    }

    // --- Active Driving Navigation Mode HUD ---
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            // Real Map View
            Positioned.fill(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(appState.currentLat, appState.currentLng),
                  initialZoom: 16.0,
                ),
                children: [
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
                  PolylineLayer(
                    polylines: [
                      if (_routePoints.isNotEmpty)
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 6.0,
                          color: AppTheme.primaryEmerald,
                        ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(appState.currentLat, appState.currentLng),
                        width: 50,
                        height: 50,
                        child: const Icon(Icons.navigation_rounded, color: AppTheme.primaryEmerald, size: 40),
                      ),
                      Marker(
                        point: LatLng(widget.destLat, widget.destLng),
                        width: 50,
                        height: 50,
                        child: const Icon(Icons.location_on_rounded, color: AppTheme.alertRed, size: 40),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Top Turn-by-Turn Instruction Banner
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmeraldDark,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryEmeraldLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.turn_slight_right_rounded, color: AppTheme.darkCharcoal, size: 32),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'بعد 800 متر',
                            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'الزم المسار الأيمن باتجاه سيطرة دهوك',
                            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Speedometer HUD & Road Warning
            Positioned(
              top: 130,
              left: 16,
              child: SpeedHudWidget(currentSpeedKmh: appState.currentSpeedKmh),
            ),

            // Live Road Warnings Floating
            Positioned(
              top: 130,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 6),
                    Text(
                      '🚦 زحمة بعد 3 كم (8 سواق أكدوا)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Driver Action Bar
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Row(
                    children: [
                      // 1-Tap Road Call Button
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentOrange,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.radar_rounded),
                          label: const Text('📡 نداء الطريق', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () => NidaaDialog.show(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 1-Tap Report Button
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.alertRed,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.add_alert_rounded),
                          label: const Text('🚨 إبلاغ سريع', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () => ReportDialog.show(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // End Navigation Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _finishTrip,
                    child: const Text('إنهاء الرحلة وعرض الملخص', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
