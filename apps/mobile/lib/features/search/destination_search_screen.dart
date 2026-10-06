import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/darb_icons.dart';
import '../../shared_widgets/darb_card.dart';
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
    {'name': 'قلعة أربيل', 'nameEn': 'Erbil Citadel', 'lat': 36.1911, 'lng': 44.0094, 'icon': DarbIconType.civic},
    {'name': 'بازار أربيل الكبير', 'nameEn': 'Grand Bazaar', 'lat': 36.1895, 'lng': 44.0120, 'icon': DarbIconType.store},
    {'name': 'مطار أربيل الدولي', 'nameEn': 'Erbil Airport', 'lat': 36.2376, 'lng': 43.9632, 'icon': DarbIconType.civic},
    {'name': 'فاميلي مول', 'nameEn': 'Family Mall', 'lat': 36.2089, 'lng': 44.0092, 'icon': DarbIconType.store},
    {'name': 'مجمع دريم سيتي', 'nameEn': 'Dream City', 'lat': 36.2213, 'lng': 44.0276, 'icon': DarbIconType.civic},
    {'name': 'شقلاوة', 'nameEn': 'Shaqlawa', 'lat': 36.4025, 'lng': 44.3214, 'icon': DarbIconType.route},
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
      backgroundColor: DarbColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Search Header
            Container(
              padding: const EdgeInsets.fromLTRB(DarbSpacing.sm, DarbSpacing.sm, DarbSpacing.lg, DarbSpacing.md),
              decoration: BoxDecoration(
                color: DarbColors.surface,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const DarbIcon(DarbIconType.back, size: 24, color: DarbColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: DarbSpacing.lg),
                      decoration: BoxDecoration(
                        color: DarbColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: DarbColors.border.withOpacity(0.5)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        textDirection: TextDirection.rtl,
                        style: DarbTypography.body.copyWith(color: DarbColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'ابحث عن مكان، شارع، مدينة...',
                          hintStyle: DarbTypography.body.copyWith(color: DarbColors.textSecondary),
                          border: InputBorder.none,
                          icon: const DarbIcon(DarbIconType.search, color: DarbColors.primaryYellow, size: 20),
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
                  ? const Center(child: CircularProgressIndicator(color: DarbColors.primaryYellow))
                  : _searchController.text.trim().length < 2
                      ? _buildQuickDestinations(isDark)
                      : _results.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  DarbIcon(DarbIconType.search, size: 64, color: DarbColors.textSecondary.withOpacity(0.4)),
                                  const SizedBox(height: DarbSpacing.md),
                                  Text('لا توجد نتائج', style: DarbTypography.section.copyWith(color: DarbColors.textSecondary)),
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
      padding: const EdgeInsets.all(DarbSpacing.lg),
      children: [
        Text(
          'وجهات سريعة',
          style: DarbTypography.section,
        ),
        const SizedBox(height: DarbSpacing.md),
        ..._quickDestinations.map((dest) => _buildDestinationTile(
          dest['name'],
          dest['nameEn'],
          dest['lat'],
          dest['lng'],
          dest['icon'] as DarbIconType,
          isDark,
        )),
      ],
    );
  }

  Widget _buildDestinationTile(String name, String subtitle, double lat, double lng, DarbIconType icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DarbSpacing.sm),
      child: DarbCard(
        isInteractive: true,
        onTap: () => _navigateToDestination(name, lat, lng),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DarbSpacing.lg, vertical: DarbSpacing.sm),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DarbSpacing.sm),
                decoration: BoxDecoration(
                  color: DarbColors.primaryYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DarbIcon(icon, color: DarbColors.primaryYellow, size: 22),
              ),
              const SizedBox(width: DarbSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name, style: DarbTypography.body),
                    Text(subtitle, style: DarbTypography.caption),
                  ],
                ),
              ),
              const DarbIcon(DarbIconType.chevronLeft, size: 16, color: DarbColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(DarbSpacing.lg),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        final name = result['display_name'] ?? '';
        final lat = double.tryParse(result['lat']?.toString() ?? '') ?? 0;
        final lng = double.tryParse(result['lon']?.toString() ?? '') ?? 0;
        final type = result['type'] ?? '';

        // Pick a smart icon based on place type
        DarbIconType icon;
        switch (type) {
          case 'hospital':
            icon = DarbIconType.hospital;
            break;
          case 'school':
          case 'university':
            icon = DarbIconType.civic;
            break;
          case 'restaurant':
          case 'cafe':
            icon = DarbIconType.restaurant;
            break;
          case 'fuel':
            icon = DarbIconType.fuel;
            break;
          case 'mosque':
            icon = DarbIconType.civic;
            break;
          default:
            icon = DarbIconType.route;
        }

        // Shorten the display name
        final parts = name.split(',');
        final shortName = parts.isNotEmpty ? parts[0].trim() : name.trim();
        final detail = parts.length > 1 ? parts.sublist(1).join(',').trim() : '';

        return Padding(
          padding: const EdgeInsets.only(bottom: DarbSpacing.sm),
          child: DarbCard(
            isInteractive: true,
            onTap: () => _navigateToDestination(shortName, lat, lng),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DarbSpacing.lg, vertical: DarbSpacing.sm),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(DarbSpacing.sm),
                    decoration: BoxDecoration(
                      color: DarbColors.primaryYellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DarbIcon(icon, color: DarbColors.primaryYellow, size: 22),
                  ),
                  const SizedBox(width: DarbSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(shortName, style: DarbTypography.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (detail.isNotEmpty)
                          Text(detail, style: DarbTypography.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const DarbIcon(DarbIconType.chevronLeft, size: 16, color: DarbColors.textSecondary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
