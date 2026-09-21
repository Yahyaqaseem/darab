import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../road_reports/report_dialog.dart';
import '../road_reports/reports_screen.dart';
import '../nidaa_al_tariq/nidaa_dialog.dart';
import '../nidaa_al_tariq/nidaa_feed_sheet.dart';
import '../fuel/fuel_screen.dart';
import '../places/places_screen.dart';
import '../emergency/emergency_services_screen.dart';
import '../profile/profile_screen.dart';
import '../navigation/navigation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;
  final _searchController = TextEditingController();
  final MapController _mapController = MapController();
  bool _hasCenteredMap = false;

  void _navigateToDestination(String destination, double lat, double lng) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NavigationScreen(
          destinationName: destination,
          destLat: lat,
          destLng: lng,
        ),
      ),
    );
  }

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final appState = Provider.of<AppState>(context, listen: false);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'اختر المحافظة / منطقة القيادة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.iraqiCities.entries.map((entry) {
                  final name = entry.value['name'] as String;
                  final isSelected = appState.currentCity == name;
                  return ChoiceChip(
                    label: Text(name, style: const TextStyle(fontFamily: 'Cairo')),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryEmerald.withOpacity(0.2),
                    onSelected: (selected) {
                      if (selected) {
                        appState.updateLocation(
                          entry.value['lat'] as double,
                          entry.value['lng'] as double,
                          name,
                        );
                        Navigator.pop(ctx);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_hasCenteredMap && appState.currentLat != 36.191113) {
      _hasCenteredMap = true;
      Future.microtask(() {
        _mapController.move(LatLng(appState.currentLat, appState.currentLng), 14.0);
      });
    }

    final screens = [
      _buildMapHomeScreen(appState, isDark),
      const ReportsScreen(),
      const FuelScreen(),
      const PlacesScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_currentTabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (idx) => setState(() => _currentTabIndex = idx),
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        indicatorColor: AppTheme.primaryEmerald.withOpacity(0.18),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded, color: AppTheme.primaryEmerald),
            label: 'الخريطة',
          ),
          NavigationDestination(
            icon: Icon(Icons.notification_important_outlined),
            selectedIcon: Icon(Icons.notification_important_rounded, color: AppTheme.primaryEmerald),
            label: 'البلاغات',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_gas_station_outlined),
            selectedIcon: Icon(Icons.local_gas_station_rounded, color: AppTheme.primaryEmerald),
            label: 'البنزين',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded, color: AppTheme.primaryEmerald),
            label: 'الأماكن',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppTheme.primaryEmerald),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }

  Widget _buildMapHomeScreen(AppState appState, bool isDark) {
    return SafeArea(
      child: Stack(
        children: [
          // Map Background Simulation View
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(appState.currentLat, appState.currentLng),
                initialZoom: 13.0,
                onPositionChanged: (position, hasGesture) {
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.darb.iraq',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(appState.currentLat, appState.currentLng),
                      width: 60,
                      height: 60,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryEmerald,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryEmerald.withOpacity(0.5),
                                  blurRadius: 16,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                    ...appState.reports.map((r) => Marker(
                      point: LatLng(r.latitude, r.longitude),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('⚠️  ( سواق أكدوا)'),
                              backgroundColor: r.color,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: r.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(color: r.color.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: Icon(r.icon, color: Colors.white, size: 16),
                        ),
                      ),
                    )),
                  ],
                ),
              ],
            ),
          ),
          
          Positioned(
            bottom: 90,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'my_location_btn',
              backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
              mini: true,
              onPressed: () async {
                await appState.startLocationTracking();
                _mapController.move(
                  LatLng(appState.currentLat, appState.currentLng),
                  15.0,
                );
              },
              child: const Icon(Icons.my_location_rounded, color: AppTheme.primaryEmerald),
            ),
          ),

          // Top Header & Search
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Top Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (query) {
                      if (query.isNotEmpty) {
                        _navigateToDestination(query, 36.8679, 42.9904);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'وين تريد تروح؟ (ابحث عن مكان، شارع، محطة...)',
                      hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryEmerald),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.location_city_rounded, color: AppTheme.secondarySandDark),
                        onPressed: _showCityPicker,
                        tooltip: 'تغيير المدينة',
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Quick Action Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: AppConstants.homeQuickActions.map((action) {
                      final key = action['key'] as String;
                      final label = action['label'] as String;
                      final icon = action['icon'] as IconData;
                      final color = action['color'] as Color;

                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Material(
                          color: isDark ? AppTheme.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          elevation: 2,
                          shadowColor: Colors.black.withOpacity(0.06),
                          child: InkWell(
                            onTap: () {
                              if (key == 'nav') {
                                _navigateToDestination('دهوك - طريق M10', 36.8679, 42.9904);
                              } else if (key == 'fuel') {
                                setState(() => _currentTabIndex = 2);
                              } else if (key == 'tire_repair') {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyServicesScreen()));
                              } else {
                                setState(() => _currentTabIndex = 3);
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  Icon(icon, color: color, size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isDark ? AppTheme.textLightPrimary : AppTheme.textDarkPrimary,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Live Active Nidaa Floating Alert Banner (If Any)
          if (appState.activeRoadQuestions.isNotEmpty)
            Positioned(
              top: 135,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NidaaFeedSheet()));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: AppTheme.accentOrange.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.radar_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '📡 نداء طريق نشط أمامك: ${appState.activeRoadQuestions.first.title}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Text('أجب الآن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo')),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom Floating Driver Tools Action Bar
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // 1-Tap Incident Report Button (🚨)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.alertRed,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: AppTheme.alertRed.withOpacity(0.4),
                    ),
                    icon: const Icon(Icons.add_alert_rounded, size: 24),
                    label: const Text(
                      '🚨 إبلاغ فوري',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Cairo'),
                    ),
                    onPressed: () => ReportDialog.show(context),
                  ),
                ),
                const SizedBox(width: 10),

                // 1-Tap Road Call Button (📡)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentOrange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: AppTheme.accentOrange.withOpacity(0.4),
                    ),
                    icon: const Icon(Icons.radar_rounded, size: 24),
                    label: const Text(
                      '📡 نداء الطريق',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Cairo'),
                    ),
                    onPressed: () => NidaaDialog.show(context),
                  ),
                ),
                const SizedBox(width: 10),

                // Emergency SOS Button (🆘)
                Container(
                  height: 54,
                  width: 54,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.car_crash_rounded, color: AppTheme.primaryEmerald, size: 28),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyServicesScreen()));
                    },
                    tooltip: 'أحتاج مساعدة / سطحة',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

