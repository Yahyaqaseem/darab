import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../navigation/navigation_screen.dart';
import '../../core/providers/app_state.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/darb_icons.dart';

class PlacesScreen extends StatefulWidget {
  final String? initialCategory;
  const PlacesScreen({super.key, this.initialCategory});
  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  late String _selectedCategory;
  final _searchController = TextEditingController();

  // Mapping from category key to icon and display name
  final List<Map<String, dynamic>> _serviceTypes = [
    {'key': 'mechanic', 'icon': DarbIconType.workshop, 'name': 'ميكانيكي'},
    {'key': 'tire', 'icon': DarbIconType.tireRepair, 'name': 'بنشر'},
    {'key': 'battery', 'icon': DarbIconType.battery, 'name': 'بطارية'},
    {'key': 'tow', 'icon': DarbIconType.brokenCar, 'name': 'سحب سيارات'},
    {'key': 'wash', 'icon': DarbIconType.carWash, 'name': 'غسيل سيارات'},
    {'key': 'parking', 'icon': DarbIconType.parking, 'name': 'مواقف'},
    {'key': 'emergency', 'icon': DarbIconType.sos, 'name': 'طوارئ'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'all';
  }

  DarbIconType _getIconForCategory(String categoryKey) {
    for (var svc in _serviceTypes) {
      if (svc['key'] == categoryKey) return svc['icon'] as DarbIconType;
    }
    return DarbIconType.workshop;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final places = appState.places;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? DarbColors.background : const Color(0xFFF8FAFC);
    final surfaceColor = isDark ? DarbColors.surface : Colors.white;
    final textColor = isDark ? DarbColors.textPrimary : DarbColors.textInversePrimary;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الخدمات', style: DarbTypography.title.copyWith(color: textColor)),
              ],
            ),
          ),
          
          // Horizontal Service Filters
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _serviceTypes.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, idx) {
                if (idx == 0) {
                  return _buildFilterChip('الكل', 'all', _selectedCategory == 'all', isDark);
                }
                final svc = _serviceTypes[idx - 1];
                return _buildFilterChip(svc['name'] as String, svc['key'] as String, _selectedCategory == svc['key'], isDark);
              },
            ),
          ),
          const SizedBox(height: 8),
          
          Expanded(
            child: places.isEmpty
                ? Center(child: Text('جاري تحميل الأماكن...', style: DarbTypography.body.copyWith(color: DarbColors.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: places.length,
                    separatorBuilder: (_, __) => const Divider(height: 24, thickness: 1, color: Colors.black12),
                    itemBuilder: (context, index) {
                      final p = places[index];
                      if (_selectedCategory != 'all' && p.categoryKey != _selectedCategory) {
                        return const SizedBox.shrink(); // Hide if not matching filter
                      }
                      
                      double distanceKm = p.distanceKm ?? 0.0;
                      if (distanceKm == 0.0 && appState.currentLat != 0) {
                        final distM = const Distance().as(LengthUnit.Meter, LatLng(appState.currentLat, appState.currentLng), LatLng(p.latitude, p.longitude));
                        distanceKm = distM / 1000.0;
                      }
                      
                      return _buildPlaceRow(p, distanceKm, surfaceColor, textColor, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String key, bool isSelected, bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? DarbColors.primaryYellow : (isDark ? DarbColors.surface : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? DarbColors.primaryYellow : (isDark ? Colors.white10 : Colors.black12)),
        ),
        child: Text(
          label,
          style: DarbTypography.body.copyWith(
            color: isSelected ? DarbColors.textInversePrimary : DarbColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceRow(PlaceModel place, double distanceKm, Color surfaceColor, Color textColor, bool isDark) {
    return Row(
      children: [
        // Clean Icon
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? DarbColors.surface : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DarbIcon(_getIconForCategory(place.categoryKey), color: DarbColors.infoBlue, size: 24),
        ),
        const SizedBox(width: 16),
        
        // Name & Rating
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                place.nameAr,
                style: DarbTypography.body.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.star_rounded, size: 14, color: DarbColors.primaryYellow),
                  const SizedBox(width: 4),
                  Text(
                    '${place.rating}',
                    style: DarbTypography.caption.copyWith(color: DarbColors.textSecondary, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  if (place.isVerified) ...[
                    Icon(Icons.verified, size: 14, color: DarbColors.successGreen),
                    const SizedBox(width: 4),
                    Text('موثوق', style: DarbTypography.caption.copyWith(color: DarbColors.successGreen)),
                  ],
                ],
              ),
            ],
          ),
        ),
        
        // Distance
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${distanceKm.toStringAsFixed(1)} km',
              style: DarbTypography.body.copyWith(
                color: DarbColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? DarbColors.surface : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'الطريق',
                  style: DarbTypography.caption.copyWith(color: DarbColors.infoBlue, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
