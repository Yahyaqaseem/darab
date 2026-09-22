import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../shared_widgets/glass_container.dart';
import '../fuel/fuel_screen.dart';
import '../places/places_screen.dart';
import '../profile/profile_screen.dart';
import '../navigation/navigation_screen.dart';
import '../nidaa_al_tariq/nidaa_feed_sheet.dart';
import '../emergency/emergency_services_screen.dart';
import '../search/destination_search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentTabIndex = 0;
  final MapController _mapController = MapController();
  bool _isMapReady = false;

  late AnimationController _dockAnimationController;
  late Animation<double> _dockAnimation;

  @override
  void initState() {
    super.initState();
    _dockAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _dockAnimation = CurvedAnimation(parent: _dockAnimationController, curve: Curves.easeOutBack);
    _dockAnimationController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).startLocationTracking();
    });
  }
  
  @override
  void dispose() {
    _dockAnimationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() => _currentTabIndex = index);
    if (index != 0) {
      _showBottomSheetForTab(index);
    }
  }

  void _showBottomSheetForTab(int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return GlassContainer(
              isDark: isDark,
              borderRadius: 30,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // Handle indicator
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                      child: Navigator(
                        onGenerateRoute: (_) => MaterialPageRoute(
                          builder: (ctx2) {
                            if (index == 1) return const FuelScreen();
                            if (index == 2) return const PlacesScreen();
                            if (index == 3) return const ProfileScreen();
                            return const SizedBox();
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      setState(() => _currentTabIndex = 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Auto-center if tracking
    if (_isMapReady && appState.currentLat != 0) {
       _mapController.move(
         LatLng(appState.currentLat, appState.currentLng), 
         _mapController.camera.zoom
       );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // LAYER 1: Full Screen Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(36.1901, 43.9930), // Default Erbil
              initialZoom: 14.0,
              onMapReady: () {
                setState(() {
                  _isMapReady = true;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: isDark ? 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png' : 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.darb.iraq',
              ),
              if (appState.currentLat != 0)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(appState.currentLat, appState.currentLng),
                      width: 60,
                      height: 60,
                      child: _buildPulsingMarker(),
                    )
                  ],
                ),
            ],
          ),

          // LAYER 2: Floating Glass Search Bar (Top)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DestinationSearchScreen()));
                  },
                  child: GlassContainer(
                    isDark: isDark,
                    borderRadius: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: AppTheme.primaryEmerald),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'إلى أين نذهب؟',
                            style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.grey),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryEmerald.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.primaryEmerald, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // LAYER 3: Floating Action Buttons (Right Edge)
          Positioned(
            right: 16,
            bottom: 120, // Above the dock
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFab(Icons.warning_rounded, AppTheme.accentOrange, () {}, isDark),
                const SizedBox(height: 16),
                _buildFab(Icons.sos_rounded, AppTheme.alertRed, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyServicesScreen()));
                }, isDark),
                const SizedBox(height: 16),
                _buildFab(Icons.my_location_rounded, isDark ? Colors.white : Colors.black87, () {
                  if (appState.currentLat != 0) {
                    _mapController.move(
                      LatLng(appState.currentLat, appState.currentLng), 
                      16.0
                    );
                  }
                }, isDark),
              ],
            ),
          ),

          // LAYER 4: Floating Animated Dock (Bottom)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0, left: 32.0, right: 32.0),
              child: ScaleTransition(
                scale: _dockAnimation,
                child: GlassContainer(
                  isDark: isDark,
                  borderRadius: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDockIcon(Icons.map_rounded, 'الخريطة', 0, isDark),
                      _buildDockIcon(Icons.local_gas_station_rounded, 'وقود', 1, isDark),
                      _buildDockIcon(Icons.place_rounded, 'أماكن', 2, isDark),
                      _buildDockIcon(Icons.person_rounded, 'حسابي', 3, isDark),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFab(IconData icon, Color color, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        isDark: isDark,
        borderRadius: 24,
        padding: const EdgeInsets.all(12),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }

  Widget _buildDockIcon(IconData icon, String label, int index, bool isDark) {
    final isSelected = _currentTabIndex == index;
    final activeColor = AppTheme.primaryEmerald;
    final inactiveColor = isDark ? Colors.white54 : Colors.black54;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? activeColor : inactiveColor, size: 24),
            if (isSelected) ...[
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: activeColor,
                  
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildPulsingMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryEmerald.withOpacity(0.2),
          ),
        ),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryEmerald,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(color: AppTheme.primaryEmerald.withOpacity(0.5), blurRadius: 8),
            ],
          ),
        ),
      ],
    );
  }
}
