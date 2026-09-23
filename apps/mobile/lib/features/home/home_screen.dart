import 'dart:async';
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
import '../emergency/emergency_services_screen.dart';
import '../search/destination_search_screen.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import '../../core/theme/darb_vector_theme.dart';
import '../../core/services/darb_tile_cache.dart';
import '../../core/theme/darb_icons.dart';
import '../../shared_widgets/darb_location_marker.dart';
import '../../shared_widgets/darb_optimized_marker_layer.dart';
import '../../shared_widgets/darb_bottom_nav.dart';
import '../road_reports/reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  bool _isMapReady = false;
  Style? _vectorStyle;
  Timer? _resumePrefetchTimer;

  final List<Map<String, dynamic>> _recentPlaces = [
    {'name': 'مستشفى رزكاري', 'nameEn': 'Rizgary Hospital', 'subtitle': 'هەولێر - Erbil', 'lat': 36.1780, 'lng': 44.0250},
    {'name': 'شارع 40', 'nameEn': '40m Road', 'subtitle': 'أربيل - Erbil', 'lat': 36.1950, 'lng': 44.0150},
    {'name': 'قلعة أربيل', 'nameEn': 'Erbil Citadel', 'subtitle': 'مركز المدينة - Qalat', 'lat': 36.1911, 'lng': 44.0094},
    {'name': 'فاميلي مول', 'nameEn': 'Family Mall', 'subtitle': 'شارع 100 متري', 'lat': 36.2089, 'lng': 44.0092},
  ];

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

  @override
  void dispose() {
    _resumePrefetchTimer?.cancel();
    super.dispose();
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

  void _navigateTo(String name, double lat, double lng) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NavigationScreen(
          destinationName: name,
          destLat: lat,
          destLng: lng,
        ),
      ),
    );
  }

  void _openMenuSheet(BuildContext context, bool isDark, String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
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
                leading: const DarbIcon(DarbIconType.fuel, color: DarbIconColors.emerald, size: 22),
                title: Text(AppStrings.tr('fuel_stations', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.pop(ctx);
                  _openScreenSheet(const FuelScreen(), isDark);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const DarbIcon(DarbIconType.workshop, color: DarbIconColors.warningOrange, size: 22),
                title: Text(AppStrings.tr('places', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.pop(ctx);
                  _openScreenSheet(const PlacesScreen(), isDark);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const DarbIcon(DarbIconType.profile, color: DarbIconColors.checkpointBlue, size: 22),
                title: Text(AppStrings.tr('profile', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.pop(ctx);
                  _openScreenSheet(const ProfileScreen(), isDark);
                },
              ),
              const Divider(height: 1),
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
                    activeColor: AppTheme.primaryEmerald,
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
          color: isDark ? AppTheme.darkCard : Colors.white,
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
        color: isSelected ? AppTheme.primaryEmerald : null,
      )),
      trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryEmerald) : null,
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
          // LAYER 1: Full-Screen Live Map (Waze style!)
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
                  _resumePrefetchTimer?.cancel();
                  DarbTilePrefetcher.pausePrefetch();
                } else if (DarbTilePrefetcher.isPrefetchPaused) {
                  _resumePrefetchTimer?.cancel();
                  _resumePrefetchTimer = Timer(const Duration(milliseconds: 600), () {
                    DarbTilePrefetcher.resumePrefetch();
                  });
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
                    memoryTileDataCacheMaxSize: 80,
                    fileCacheMaximumSizeInBytes: 256 * 1024 * 1024,
                    maximumTileSubstitutionDifference: 3,
                    maximumZoom: 18.0,
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
              // High-Performance Zoom-Adaptive & Viewport-Culled Marker Layer
              DarbOptimizedMarkerLayer(
                onOpenSheet: (screen, isDark) => _openScreenSheet(screen, isDark),
                onNavigateTo: (name, lat, lng) => _navigateTo(name, lat, lng),
              ),
              // Real-Time GPS User Location Marker Layer (Isolated, ZERO full map rebuilds)
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

          // LAYER 2: Top-Left Navigation Controls (DARB Menu & Minimal Compass)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: RepaintBoundary(
                child: Row(
                children: [
                  // Hamburger Menu Button
                  DarbIconButton(
                    icon: DarbIconType.menu,
                    onTap: () => _openMenuSheet(context, isDark, lang),
                  ),
                  const SizedBox(width: 10),
                  // Minimal Circular Navigation Compass
                  CompassWidget(
                    onTap: () {
                      if (_isMapReady) {
                        _mapController.rotate(0.0);
                      }
                    },
                  ),
                  const Spacer(),
                  // Top-Right Quick Road Actions: Warning & SOS
                  DarbIconButton(
                    icon: DarbIconType.quickReport,
                    iconColor: DarbIconColors.warningOrange,
                    borderColor: DarbIconColors.warningOrange.withOpacity(0.4),
                    onTap: () {
                      showDialog(context: context, builder: (_) => const ReportDialog());
                    },
                  ),
                  const SizedBox(width: 10),
                  DarbSOSButton(
                    size: 44,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyServicesScreen()));
                    },
                  ),
                ],
              ),
            ),
          ),
          ),

          // LAYER 3: Re-center GPS Button (Bottom-Left)
          Positioned(
            left: 16,
            bottom: 160,
            child: RepaintBoundary(
              child: DarbIconButton(
                icon: DarbIconType.myLocation,
                size: 48,
                onTap: () {
                  if (_isMapReady) {
                    final curPos = appState.userLocationNotifier.value;
                    _animatedMapMove(curPos, 16.0);
                  }
                },
              ),
            ),
          ),

          // LAYER 4: Search Bar & Floating Bottom Nav
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Floating Search Bar & Quick Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const DestinationSearchScreen()));
                          },
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: isDark ? DarbColors.surface : Colors.white,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                              ),
                            ),
                            child: Row(
                              children: [
                                const DarbIcon(DarbIconType.search, color: DarbColors.textSecondary, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AppStrings.tr('where_to', lang),
                                    style: DarbTypography.body.copyWith(
                                      color: DarbColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: DarbColors.border,
                                  margin: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                const Icon(Icons.mic_rounded, color: DarbColors.textSecondary, size: 22),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Floating Bottom Nav
                DarbBottomNav(
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
              ],
            ),
          ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Sheet Drag Handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 12),
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Waze Search Bar: "إلى أين؟" / "Where to?"
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const DestinationSearchScreen()));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const DarbIcon(DarbIconType.search, color: Colors.grey, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                AppStrings.tr('where_to', lang),
                                style: const TextStyle(fontSize: 17, color: Colors.grey, fontWeight: FontWeight.w500),
                              ),
                            ),
                            const Icon(Icons.mic_rounded, color: Colors.grey, size: 20),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Quick Chips Row: [المنزل 🏠], [العمل 💼], [+ جديد]
                    Row(
                      children: [
                        _buildQuickChip(
                          icon: DarbIconType.home,
                          label: AppStrings.tr('home', lang),
                          isDark: isDark,
                          onTap: () => _navigateTo(AppStrings.tr('home', lang), 36.1911, 44.0094),
                        ),
                        const SizedBox(width: 8),
                        _buildQuickChip(
                          icon: DarbIconType.work,
                          label: AppStrings.tr('work', lang),
                          isDark: isDark,
                          onTap: () => _navigateTo(AppStrings.tr('work', lang), 36.2089, 44.0092),
                        ),
                        const SizedBox(width: 8),
                        _buildQuickChip(
                          icon: DarbIconType.add,
                          label: AppStrings.tr('new_place', lang),
                          isDark: isDark,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const DestinationSearchScreen()));
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Recent Destinations Header: "السابقة" / "Recent"
                    Text(
                      AppStrings.tr('recent', lang),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),

                    const SizedBox(height: 8),

                    // Recent Places List
                    ..._recentPlaces.map(
                      (p) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: DarbIcon(DarbIconType.route, size: 18, color: Colors.grey),
                            ),
                          ),
                          title: Text(
                            lang == 'en' ? p['nameEn'] : p['name'],
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          subtitle: Text(
                            p['subtitle'],
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                          onTap: () => _navigateTo(lang == 'en' ? p['nameEn'] : p['name'], p['lat'], p['lng']),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildQuickChip({
    required DarbIconType icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DarbIcon(icon, size: 16, color: DarbIconColors.emerald),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
