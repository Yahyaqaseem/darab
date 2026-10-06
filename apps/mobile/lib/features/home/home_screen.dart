import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_strings.dart';
import '../../shared_widgets/compass_widget.dart';
import '../fuel/fuel_screen.dart';
import '../places/places_screen.dart';
import '../profile/profile_screen.dart';
import '../navigation/navigation_screen.dart';
import '../road_reports/report_dialog.dart';
import '../road_reports/reports_screen.dart';
import '../emergency/emergency_services_screen.dart';
import '../search/destination_search_screen.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import '../../core/theme/darb_vector_theme.dart';
import '../../core/services/darb_tile_cache.dart';
import '../../core/theme/darb_icons.dart';
import '../../shared_widgets/darb_location_marker.dart';
import '../../shared_widgets/darb_bottom_nav.dart';
import '../nidaa_al_tariq/nidaa_dialog.dart';
import '../../core/utils/darb_clusterer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  bool _isMapReady = false;
  Style? _vectorStyle;
  double _currentZoom = 15.0;
  final ValueNotifier<double> _zoomNotifier = ValueNotifier<double>(15.0);

  @override
  void initState() {
    super.initState();
    DarbVectorTheme.loadStyle().then((style) {
      if (mounted) {
        setState(() => _vectorStyle = style);
        final appState = Provider.of<AppState>(context, listen: false);
        final lat = appState.currentLat != 0 ? appState.currentLat : 36.1911;
        final lng = appState.currentLng != 0 ? appState.currentLng : 44.0091;
        if (DarbVectorTheme.cachingTileProvider != null) {
          DarbTilePrefetcher.prefetchAround(
            center: LatLng(lat, lng),
            zoom: 15.0,
            radius: 2,
            provider: DarbVectorTheme.cachingTileProvider!,
          );
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.startLocationTracking();
      if (appState.fuelStations.isEmpty || appState.places.isEmpty) {
        appState.loadNearbyData();
      }
    });
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final camera = _mapController.camera;
    final latTween = Tween<double>(begin: camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: camera.zoom, end: destZoom);

    final controller = AnimationController(duration: const Duration(milliseconds: 550), vsync: this);
    final animation = CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  void _openMenuSheet(BuildContext context, bool isDark, String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? DarbColors.surface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 16)],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const DarbIcon(DarbIconType.share, color: DarbIconColors.purple, size: 22),
                title: Text(AppStrings.tr('app_language', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text(
                  lang == 'ar' ? 'العربية' : (lang == 'ku' ? 'کوردی' : 'English'),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: DarbIconColors.emerald),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _openLanguagePicker(context, isDark);
                },
              ),
              const Divider(height: 1),
              Consumer<AppState>(
                builder: (context, appState, child) => ListTile(
                  leading: Icon(
                    appState.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: Colors.amber,
                  ),
                  title: Text(
                    appState.isDarkMode
                        ? (lang == 'en' ? 'Dark Mode' : (lang == 'ku' ? 'دۆخی تاریک' : 'الوضع الليلي'))
                        : (lang == 'en' ? 'Light Mode' : (lang == 'ku' ? 'دۆخی ڕووناک' : 'الوضع النهاري')),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Switch(
                    value: appState.isDarkMode,
                    activeColor: AppTheme.primaryYellow,
                    onChanged: (_) => appState.toggleTheme(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openScreenSheet(Widget screen, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 16)],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Expanded(child: screen),
            ],
          ),
        ),
      ),
    );
  }

  void _openLanguagePicker(BuildContext context, bool isDark) {
    final appState = Provider.of<AppState>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? DarbColors.surface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('اختر اللغة / زمان هەڵبژێرە / Select Language', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              _buildLangTile(ctx, 'العربية (Arabic)', 'ar', appState),
              const Divider(height: 1),
              _buildLangTile(ctx, 'کوردی (Kurdish)', 'ku', appState),
              const Divider(height: 1),
              _buildLangTile(ctx, 'English', 'en', appState),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangTile(BuildContext ctx, String label, String code, AppState appState) {
    final isSelected = appState.currentLanguage == code;
    return ListTile(
      title: Text(label, textAlign: TextAlign.center, style: TextStyle(
        fontSize: 17,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppTheme.primaryYellow : null,
      )),
      trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryYellow) : null,
      onTap: () {
        appState.setLanguage(code);
        Navigator.pop(ctx);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = appState.currentLanguage;

    final initialLat = appState.currentLat != 0 ? appState.currentLat : 36.1911;
    final initialLng = appState.currentLng != 0 ? appState.currentLng : 44.0091;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // LAYER 1: Full-Screen Live Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(initialLat, initialLng),
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
                } else if (DarbTilePrefetcher.isPrefetchPaused) {
                  Future.delayed(const Duration(milliseconds: 500), () {
                    DarbTilePrefetcher.resumePrefetch();
                  });
                }
                if (pos.zoom != null && (pos.zoom! - _currentZoom).abs() > 0.5) {
                  _currentZoom = pos.zoom!;
                  _zoomNotifier.value = pos.zoom!;
                }
              },
              onMapReady: () {
                setState(() => _isMapReady = true);
              },
            ),
            children: [
              if (_vectorStyle != null)
                RepaintBoundary(
                  child: VectorTileLayer(
                    theme: _vectorStyle!.theme,
                    sprites: _vectorStyle!.sprites,
                    tileProviders: _vectorStyle!.providers,
                    layerMode: VectorTileLayerMode.raster,
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
              // Static & POI Marker Layer
              Consumer<AppState>(
                builder: (context, state, _) {
                  return ValueListenableBuilder<double>(
                    valueListenable: _zoomNotifier,
                    builder: (context, zoom, _) {
                      // Apply clustering
                      
                      final fuelClusters = DarbMapClusterer.clusterItems(
                        items: state.fuelStations,
                        getLat: (s) => (s as dynamic).latitude,
                        getLng: (s) => (s as dynamic).longitude,
                        currentZoom: zoom,
                        clusterRadiusPixels: 60.0,
                      );

                      return MarkerLayer(
                        markers: [
                          // Reports
                          ...state.reports
                              .where((r) => zoom >= 12.0 || r.type == 'ACCIDENT' || r.type == 'CLOSURE')
                              .map((r) => Marker(
                                point: LatLng(r.latitude, r.longitude),
                                width: 38,
                                height: 44,
                                alignment: Alignment.topCenter,
                                child: DarbReportMarker(report: r, size: 36),
                              )),
                              
                          // Fuel Stations / Clusters
                          if (zoom >= 11.0)
                            ...fuelClusters.map((cluster) {
                              if (cluster.count > 1) {
                                // Cluster Bubble
                                return Marker(
                                  point: cluster.position,
                                  width: 48,
                                  height: 48,
                                  alignment: Alignment.center,
                                  child: GestureDetector(
                                    onTap: () {
                                      _animatedMapMove(cluster.position, zoom + 2.0);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: DarbColors.surface,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: DarbColors.primaryYellow, width: 2),
                                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${cluster.count}',
                                        style: DarbTypography.numeric.copyWith(
                                          color: DarbColors.primaryYellow,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                // Single POI
                                final s = cluster.items.first;
                                return Marker(
                                  point: LatLng(s.latitude, s.longitude),
                                  width: zoom >= 14.5 ? 90 : 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  child: DarbFuelMarker(
                                    station: s,
                                    currentZoom: zoom,
                                    onTap: () => _openScreenSheet(const FuelScreen(), isDark),
                                  ),
                                );
                              }
                            }),
                        ],
                      );
                    },
                  );
                },
              ),
              // Real-Time GPS User Location Marker Layer
              ValueListenableBuilder<LatLng>(
                valueListenable: appState.userLocationNotifier,
                builder: (context, userPos, _) {
                  return MarkerLayer(
                    markers: [
                      Marker(
                        point: userPos,
                        width: 72,
                        height: 72,
                        alignment: Alignment.center,
                        child: ValueListenableBuilder<double>(
                          valueListenable: appState.userHeadingNotifier,
                          builder: (context, heading, _) {
                            return ValueListenableBuilder<double>(
                              valueListenable: appState.userSpeedNotifier,
                              builder: (context, speed, _) {
                                return ValueListenableBuilder<double>(
                                  valueListenable: appState.userAccuracyNotifier,
                                  builder: (context, accuracy, _) {
                                    return DarbLocationMarker(
                                      position: userPos,
                                      bearing: heading,
                                      speedKmh: speed,
                                      accuracyMeters: accuracy,
                                      size: 42,
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),

          // LAYER 2: Top UI Area (SOS, Search, Menu)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // SOS Button
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyServicesScreen()));
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: DarbColors.dangerRed,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: DarbColors.dangerRed.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Search Bar
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const DestinationSearchScreen()));
                          },
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: isDark ? DarbColors.surface : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                              ),
                            ),
                            child: Directionality(
                              textDirection: (lang == 'ar' || lang == 'ku') ? TextDirection.rtl : TextDirection.ltr,
                              child: Row(
                                children: [
                                  const DarbIcon(DarbIconType.search, color: DarbColors.textSecondary, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      lang == 'ku' ? 'بۆ کوێ؟' : (lang == 'ar' ? 'إلى أين؟' : 'Where to?'),
                                      style: DarbTypography.body.copyWith(
                                        color: DarbColors.textSecondary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Menu
                      GestureDetector(
                        onTap: () => _openMenuSheet(context, isDark, lang),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark ? DarbColors.surface : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
                            ],
                            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                          ),
                          alignment: Alignment.center,
                          child: DarbIcon(DarbIconType.menu, color: isDark ? Colors.white : Colors.black87, size: 22),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Compass Right Aligned
                  Align(
                    alignment: Alignment.centerRight,
                    child: CompassWidget(
                      onTap: () {
                        if (_isMapReady) {
                          _mapController.rotate(0.0);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // LAYER 3: Re-center & Road Call (Bottom-Right, above Nav)
          Positioned(
            right: 16,
            bottom: 100, // Above bottom nav
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Road Call (نداء الطريق)
                GestureDetector(
                  onTap: () {
                    NidaaDialog.show(context);
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: DarbColors.primaryYellow,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: DarbColors.primaryYellow.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const DarbIcon(DarbIconType.roadCall, color: DarbColors.textInversePrimary, size: 28),
                  ),
                ),
                const SizedBox(height: 16),
                // Recenter
                GestureDetector(
                  onTap: () {
                    if (_isMapReady) {
                      final curPos = appState.userLocationNotifier.value;
                      _animatedMapMove(curPos, 16.0);
                    }
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? DarbColors.surface : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                      border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                    ),
                    alignment: Alignment.center,
                    child: DarbIcon(DarbIconType.myLocation, color: isDark ? Colors.white : Colors.black87, size: 22),
                  ),
                ),
              ],
            ),
          ),

          // LAYER 4: Bottom Navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DarbBottomNav(
              currentIndex: 0,
              isDark: isDark,
              onTabSelected: (index) {
                if (index == 0) return; // Already on Map
                if (index == 1) _openScreenSheet(const ReportsScreen(), isDark);
                if (index == 2) _openScreenSheet(const FuelScreen(), isDark);
                if (index == 3) _openScreenSheet(const PlacesScreen(), isDark);
                if (index == 4) _openScreenSheet(const ProfileScreen(), isDark);
              },
            ),
          ),
        ],
      ),
    );
  }
}
