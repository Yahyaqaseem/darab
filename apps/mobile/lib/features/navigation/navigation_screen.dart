import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:latlong2/latlong.dart' as ll2;
import 'package:provider/provider.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/polyline_decoder.dart';
import '../../core/localization/app_strings.dart';
import '../../shared_widgets/speed_hud_widget.dart';
import '../../shared_widgets/driver_safe_button.dart';
import '../nidaa_al_tariq/nidaa_dialog.dart';
import '../road_reports/report_dialog.dart';
import '../../core/theme/darb_icons.dart';
import '../../shared_widgets/darb_card.dart';
import '../../shared_widgets/darb_button.dart';
import '../../core/utils/chevron_generator.dart';
import '../../core/utils/route_simulator.dart';

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
  MaplibreMapController? _mapController;
  int _selectedRouteIndex = 0;
  bool _isRouteSelecting = true;
  Map<String, dynamic>? _routesData;
  bool _isLoading = true;
  List<LatLng> _routePoints = [];
  final ValueNotifier<bool> _isFollowingUserNotifier = ValueNotifier<bool>(true);
  AppState? _appState;
  Symbol? _destinationMarker;
  Line? _routeLine;
  Line? _routeLineShadow;
  Line? _routeLineHighlight;
  RouteSimulator? _simulator;

  @override
  void initState() {
    super.initState();
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
    _isFollowingUserNotifier.dispose();
    _appState?.userLocationNotifier.removeListener(_onUserLocationChanged);
    _simulator?.stop();
    super.dispose();
  }

  void _onMapCreated(MaplibreMapController controller) {
    _mapController = controller;
    _drawDestinationMarker();
    _drawRoute();
  }

  Future<void> _onStyleLoaded() async {
    if (_mapController == null) return;
    _drawDestinationMarker();
    _drawRoute();
  }

  void _onUserLocationChanged() {
    if (!mounted || _isRouteSelecting || !_isFollowingUserNotifier.value || _appState == null || _mapController == null) return;
    final userPos = _appState!.userLocationNotifier.value;
    final bearing = _appState!.userHeadingNotifier.value;
    final speed = _appState!.userSpeedNotifier.value;
    final targetZoom = _calculateDynamicZoom(speed);

    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(userPos.latitude, userPos.longitude),
          zoom: targetZoom,
          tilt: 60.0, // TRUE 3D PITCH
          bearing: speed > 2.0 ? bearing : 0.0,
        )
      ),
      duration: const Duration(milliseconds: 1000),
    );
  }

  double _calculateDynamicZoom(double speedKmh) {
    if (speedKmh > 75) return 15.0;
    if (speedKmh > 45) return 16.0;
    if (speedKmh > 20) return 17.0;
    return 17.5;
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

        final routes = data['routes'] as List? ?? [];
        if (routes.isNotEmpty) {
          final firstRoute = routes[0];
          final geom = firstRoute['geometry'] as String?;
          if (geom != null) {
            final points = PolylineDecoder.decode(geom);
            setState(() {
              _routePoints = points.map((p) => LatLng(p.latitude, p.longitude)).toList();
            });
            
            if (_routePoints.isNotEmpty && _mapController != null) {
               _drawRoute();
               
               // Compute bounds
               double minLat = _routePoints.first.latitude;
               double maxLat = _routePoints.first.latitude;
               double minLng = _routePoints.first.longitude;
               double maxLng = _routePoints.first.longitude;
               for (var p in _routePoints) {
                 if (p.latitude < minLat) minLat = p.latitude;
                 if (p.latitude > maxLat) maxLat = p.latitude;
                 if (p.longitude < minLng) minLng = p.longitude;
                 if (p.longitude > maxLng) maxLng = p.longitude;
               }
               _mapController!.animateCamera(
                 CameraUpdate.newLatLngBounds(
                   LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)),
                   top: 100, bottom: 300, left: 40, right: 40
                 )
               );
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
  
  Future<void> _drawDestinationMarker() async {
    if (_mapController == null) return;
    if (_destinationMarker != null) {
      await _mapController!.removeSymbol(_destinationMarker!);
    }
    _destinationMarker = await _mapController!.addSymbol(SymbolOptions(
      geometry: LatLng(widget.destLat, widget.destLng),
      iconImage: 'marker-15', // Default maplibre marker if custom isn't loaded
      iconSize: 2.5,
      iconColor: '#E63946',
    ));
  }

  Future<void> _drawRoute() async {
    if (_mapController == null || _routePoints.isEmpty) return;
    
    if (_routeLineShadow != null) await _mapController!.removeLine(_routeLineShadow!);
    if (_routeLine != null) await _mapController!.removeLine(_routeLine!);
    if (_routeLineHighlight != null) await _mapController!.removeLine(_routeLineHighlight!);

    _routeLineShadow = await _mapController!.addLine(LineOptions(
      geometry: _routePoints,
      lineColor: '#0A1A3A', // Deep blue shadow
      lineWidth: 12.0,
      lineOpacity: 0.9,
    ));
    
    _routeLine = await _mapController!.addLine(LineOptions(
      geometry: _routePoints,
      lineColor: '#00D1FF', // Electric Cyan Blue!
      lineWidth: 7.0,
    ));
    
    _routeLineHighlight = await _mapController!.addLine(LineOptions(
      geometry: _routePoints,
      lineColor: '#FFFFFF',
      lineWidth: 2.5,
      lineOpacity: 0.8,
    ));
  }

  void _startDrive() {
    _isFollowingUserNotifier.value = true;
    setState(() {
      _isRouteSelecting = false;
    });
    final appState = Provider.of<AppState>(context, listen: false);
    final userPos = appState.userLocationNotifier.value;
    
    final routes = _routesData?['routes'] as List? ?? [];
    if (routes.isNotEmpty) {
      final selected = routes[_selectedRouteIndex.clamp(0, routes.length - 1)];
      appState.selectRoutePreview(selected, widget.destinationName, widget.destLat, widget.destLng);
    }
    
    appState.startNavigation();
    
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(userPos.latitude, userPos.longitude),
            zoom: 17.0,
            tilt: 60.0, // TRUE 3D PITCH
            bearing: appState.userHeadingNotifier.value,
          )
        ),
        duration: const Duration(milliseconds: 1200),
      );
    }
  }



  void _startSimulation() {
    _isFollowingUserNotifier.value = true;
    setState(() {
      _isRouteSelecting = false;
    });
    
    final appState = Provider.of<AppState>(context, listen: false);
    final routes = _routesData?['routes'] as List? ?? [];
    if (routes.isNotEmpty) {
      final selected = routes[_selectedRouteIndex.clamp(0, routes.length - 1)];
      appState.selectRoutePreview(selected, widget.destinationName, widget.destLat, widget.destLng);
    }
    
    appState.startNavigation();
    
    _simulator?.stop();
    _simulator = RouteSimulator(
      routePoints: _routePoints,
      speedKmh: 65.0, // Simulate 65 km/h
      onUpdate: (loc, bearing, speed) {
        if (!mounted) return;
        // Mock the user's location via AppState
        appState.userLocationNotifier.value = ll2.LatLng(loc.latitude, loc.longitude);
        appState.userHeadingNotifier.value = bearing;
        appState.userSpeedNotifier.value = speed;
      },
      onFinish: () {
        if (mounted) _finishTrip();
      },
    );
    
    _simulator!.start();
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
          // LAYER 1: TRUE 3D MAPLIBRE MAP
          MaplibreMap(
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            styleString: 'asset://assets/map/darb_style.json',
            initialCameraPosition: CameraPosition(
              target: LatLng(userLat, userLng),
              zoom: 15.0,
            ),
            myLocationEnabled: true,
            myLocationTrackingMode: MyLocationTrackingMode.None,
            myLocationRenderMode: MyLocationRenderMode.COMPASS,
            compassEnabled: false,
            onCameraIdle: () {
              // Stop tracking if user manually pans
            },
          ),

          // LAYER 1.5: THE PREMIUM 3D CHEVRON (Only visible when tracking user)
          ValueListenableBuilder<bool>(
            valueListenable: _isFollowingUserNotifier,
            builder: (context, isFollowing, _) {
              if (!isFollowing || _isRouteSelecting) return const SizedBox.shrink();
              return Positioned(
                left: 0,
                right: 0,
                // Center slightly below optical center to match 60-degree pitch
                bottom: MediaQuery.of(context).size.height * 0.35, 
                child: Center(
                  child: IgnorePointer(
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateX(1.0), // Pitch the chevron flat to match the map
                      alignment: Alignment.center,
                      child: const PremiumChevronWidget(size: 100.0),
                    ),
                  ),
                ),
              );
            },
          ),

          // Recenter Floating Button
          ValueListenableBuilder<bool>(
            valueListenable: _isFollowingUserNotifier,
            builder: (context, isFollowing, _) {
              if (isFollowing) return const SizedBox.shrink();
              return Positioned(
                left: 16,
                bottom: 230,
                child: RepaintBoundary(
                  child: GestureDetector(
                    onTap: () {
                      _isFollowingUserNotifier.value = true;
                      _onUserLocationChanged();
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF07101F).withOpacity(0.7) : Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(24),
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
                ),
              );
            },
          ),

          // LAYER 2: Top Glass Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: RepaintBoundary(
                child: Row(
                  children: [
                    DarbIconButton(
                      icon: DarbIconType.back,
                      size: 48,
                      onTap: _finishTrip,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: DarbSpacing.lg, vertical: DarbSpacing.md),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF07101F).withOpacity(0.65) : Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.05)),
                            ),
                            child: Row(
                              children: [
                                DarbIcon(
                                  _isRouteSelecting ? DarbIconType.route : DarbIconType.recenter,
                                  color: DarbColors.primaryYellow,
                                  size: 20,
                                ),
                                const SizedBox(width: DarbSpacing.sm),
                                Expanded(
                                  child: Text(
                                    widget.destinationName,
                                    style: DarbTypography.section,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
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

          // LAYER 4: Bottom Panel (Glassmorphism!)
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: RepaintBoundary(
                child: Padding(
                  padding: const EdgeInsets.all(DarbSpacing.lg),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: Container(
                        padding: const EdgeInsets.all(DarbSpacing.xl),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF07101F).withOpacity(0.65) : Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.05)),
                        ),
                        child: _isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: DarbColors.primaryYellow)),
                                  const SizedBox(width: 16),
                                  Text(
                                    lang == 'en' ? 'Calculating best route...' : (lang == 'ku' ? 'خەریکی دۆزینەوەی باشترین ڕێگایە...' : 'جارِ حساب أفضل مسار...'),
                                    style: DarbTypography.body.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              )
                            : Selector<AppState, Map<String, dynamic>?>(
                                selector: (_, s) => s.activeRoute,
                                builder: (context, activeRoute, _) {
                                  final routeToDisplay = activeRoute ?? currentRoute;
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      if (!_isRouteSelecting) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: DarbColors.successGreen.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: DarbColors.successGreen.withOpacity(0.2)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.turn_slight_right, color: DarbColors.successGreen, size: 28),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'استمر في القيادة',
                                                      style: DarbTypography.body.copyWith(
                                                        color: isDark ? Colors.white : Colors.black,
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 18,
                                                      ),
                                                    ),
                                                    Text(
                                                      'بناءً على مسار OSRM الحالي',
                                                      style: DarbTypography.caption.copyWith(color: DarbColors.successGreen),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  routeToDisplay?['durationFormatted'] ?? '15 دقيقة',
                                                  style: DarbTypography.numeric.copyWith(
                                                    color: DarbColors.successGreen,
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${routeToDisplay?['distanceKm'] ?? 5.2} كم',
                                                style: DarbTypography.numeric.copyWith(
                                                  color: isDark ? Colors.white : Colors.black,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'وصول ${routeToDisplay?['eta'] ?? '09:20'}',
                                                style: DarbTypography.caption.copyWith(
                                                  color: DarbColors.textSecondary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      if (_isRouteSelecting) ...[
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: DarbColors.primaryYellow,
                                              foregroundColor: DarbColors.textInversePrimary,
                                              elevation: 0,
                                              minimumSize: const Size.fromHeight(54),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            ),
                                            onPressed: _startDrive,
                                            child: const Text('ابدأ الملاحة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                                          ),
                                          const SizedBox(height: 12),
                                          OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: DarbColors.successGreen,
                                              side: BorderSide(color: DarbColors.successGreen.withOpacity(0.5)),
                                              minimumSize: const Size.fromHeight(48),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            ),
                                            icon: const Icon(Icons.play_circle_fill),
                                            label: const Text('محاكاة القيادة (تجربة)', style: TextStyle(fontWeight: FontWeight.bold)),
                                            onPressed: _startSimulation,
                                          ),
                                        ] else 
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isDark ? DarbColors.background : const Color(0xFFF1F5F9),
                                            foregroundColor: DarbColors.dangerRed,
                                            elevation: 0,
                                            minimumSize: const Size.fromHeight(54),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          ),
                                          onPressed: _finishTrip,
                                          child: const Text('إنهاء الرحلة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                        ),
                                    ],
                                  );
                                },
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
