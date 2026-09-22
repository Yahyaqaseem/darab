import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../navigation/navigation_screen.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';

class PlacesScreen extends StatefulWidget {
  final String? initialCategory;

  const PlacesScreen({super.key, this.initialCategory});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  late String _selectedCategory;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'all';
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final places = appState.places;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = places.where((p) {
      if (_selectedCategory != 'all' && p.categoryKey != _selectedCategory) {
        return false;
      }
      if (_searchController.text.isNotEmpty) {
        return p.nameAr.contains(_searchController.text.trim());
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('دليل الأماكن والخدمات'),
      ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'ابحث عن مكان، ورشة، مطعم...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: isDark ? AppTheme.darkCard : AppTheme.lightSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),

          // Categories Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildCatChip('all', 'الكل'),
                const SizedBox(width: 8),
                _buildCatChip('tire_repair', '🛞 بنجرجية'),
                const SizedBox(width: 8),
                _buildCatChip('mechanic', '🔧 ورش وميكانيك'),
                const SizedBox(width: 8),
                _buildCatChip('towing', '🚜 سطحة وإنقاذ'),
                const SizedBox(width: 8),
                _buildCatChip('restaurant', '🍔 مطاعم'),
                const SizedBox(width: 8),
                _buildCatChip('cafe', '☕ كافيهات'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('لا توجد أماكن مطابقة', style: TextStyle(fontFamily: 'Cairo')))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, idx) {
                      final p = filtered[idx];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.nameAr,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo'),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          p.address,
                                          style: TextStyle(
                                            color: isDark ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
                                            fontSize: 12,
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                                      const SizedBox(width: 2),
                                      Text(
                                        p.rating.toString(),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(p.openingHours, style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Cairo')),
                                    ],
                                  ),
                                  if (p.distanceKm != null)
                                    Text(
                                      '${p.distanceKm} كم من موقعك',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald, fontFamily: 'Cairo'),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryEmerald,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(0, 40),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      icon: const Icon(Icons.navigation_rounded, size: 16),
                                      label: const Text('اذهب إليه', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                                      onPressed: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => NavigationScreen(destinationName: p.nameAr, destLat: p.latitude, destLng: p.longitude,)));
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(0, 40),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    icon: const Icon(Icons.phone_rounded, size: 16),
                                    label: const Text('اتصال', style: TextStyle(fontFamily: 'Cairo')),
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatChip(String key, String label) {
    final isSelected = _selectedCategory == key;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontFamily: 'Cairo', fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: AppTheme.primaryEmerald.withOpacity(0.2),
      onSelected: (selected) {
        if (selected) setState(() => _selectedCategory = key);
      },
    );
  }
}
