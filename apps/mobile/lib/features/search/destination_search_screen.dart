import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_theme.dart';
import '../navigation/navigation_screen.dart';

class DestinationSearchScreen extends StatefulWidget {
  const DestinationSearchScreen({super.key});

  @override
  State<DestinationSearchScreen> createState() => _DestinationSearchScreenState();
}

class _DestinationSearchScreenState extends State<DestinationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Dio _dio = Dio();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  // Popular Iraq destinations for quick access
  final List<Map<String, dynamic>> _quickDestinations = [
    {'name': 'قلعة أربيل', 'nameEn': 'Erbil Citadel', 'lat': 36.1911, 'lng': 44.0094, 'icon': Icons.castle_rounded},
    {'name': 'بازار أربيل الكبير', 'nameEn': 'Grand Bazaar', 'lat': 36.1895, 'lng': 44.0120, 'icon': Icons.store_rounded},
    {'name': 'مطار أربيل الدولي', 'nameEn': 'Erbil Airport', 'lat': 36.2376, 'lng': 43.9632, 'icon': Icons.flight_rounded},
    {'name': 'فاميلي مول', 'nameEn': 'Family Mall', 'lat': 36.2089, 'lng': 44.0092, 'icon': Icons.shopping_bag_rounded},
    {'name': 'مجمع دريم سيتي', 'nameEn': 'Dream City', 'lat': 36.2213, 'lng': 44.0276, 'icon': Icons.park_rounded},
    {'name': 'شقلاوة', 'nameEn': 'Shaqlawa', 'lat': 36.4025, 'lng': 44.3214, 'icon': Icons.landscape_rounded},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }
    setState(() => _isLoading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchNominatim(query.trim());
    });
  }

  Future<void> _searchNominatim(String query) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': '8',
          'countrycodes': 'iq',
          'accept-language': 'ar,en',
          'addressdetails': '1',
        },
        options: Options(headers: {
          'User-Agent': 'DarbIraqApp/1.0',
        }),
      );

      if (mounted) {
        setState(() {
          _results = List<Map<String, dynamic>>.from(response.data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _results = [];
        });
      }
    }
  }

  void _navigateToDestination(String name, double lat, double lng) {
    Navigator.pushReplacement(
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Search Header
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkBackground : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        textDirection: TextDirection.rtl,
                        decoration: const InputDecoration(
                          hintText: 'ابحث عن مكان، شارع، مدينة...',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          icon: Icon(Icons.search_rounded, color: AppTheme.primaryEmerald),
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Results
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryEmerald))
                  : _searchController.text.trim().length < 2
                      ? _buildQuickDestinations(isDark)
                      : _results.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.withOpacity(0.4)),
                                  const SizedBox(height: 12),
                                  const Text('لا توجد نتائج', style: TextStyle(color: Colors.grey, fontSize: 16)),
                                ],
                              ),
                            )
                          : _buildSearchResults(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDestinations(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'وجهات سريعة',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._quickDestinations.map((dest) => _buildDestinationTile(
          dest['name'],
          dest['nameEn'],
          dest['lat'],
          dest['lng'],
          dest['icon'],
          isDark,
        )),
      ],
    );
  }

  Widget _buildDestinationTile(String name, String subtitle, double lat, double lng, IconData icon, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryEmerald.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryEmerald, size: 22),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: () => _navigateToDestination(name, lat, lng),
      ),
    );
  }

  Widget _buildSearchResults(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        final name = result['display_name'] ?? '';
        final lat = double.tryParse(result['lat']?.toString() ?? '') ?? 0;
        final lng = double.tryParse(result['lon']?.toString() ?? '') ?? 0;
        final type = result['type'] ?? '';

        // Pick a smart icon based on place type
        IconData icon;
        switch (type) {
          case 'hospital':
            icon = Icons.local_hospital_rounded;
            break;
          case 'school':
          case 'university':
            icon = Icons.school_rounded;
            break;
          case 'restaurant':
          case 'cafe':
            icon = Icons.restaurant_rounded;
            break;
          case 'fuel':
            icon = Icons.local_gas_station_rounded;
            break;
          case 'mosque':
            icon = Icons.mosque_rounded;
            break;
          default:
            icon = Icons.place_rounded;
        }

        // Shorten the display name
        final parts = name.split(',');
        final shortName = parts.length > 2 ? '${parts[0]}, ${parts[1]}' : name;
        final detail = parts.length > 2 ? parts.sublist(2).join(',').trim() : '';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryEmerald.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primaryEmerald, size: 22),
            ),
            title: Text(shortName, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: detail.isNotEmpty
                ? Text(detail, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)
                : null,
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
            onTap: () => _navigateToDestination(shortName, lat, lng),
          ),
        );
      },
    );
  }
}
