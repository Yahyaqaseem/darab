import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/darb_icons.dart';
import '../../shared_widgets/driver_safe_button.dart';

class EmergencyServicesScreen extends StatefulWidget {
  const EmergencyServicesScreen({super.key});

  @override
  State<EmergencyServicesScreen> createState() => _EmergencyServicesScreenState();
}

class _EmergencyServicesScreenState extends State<EmergencyServicesScreen> {
  String _selectedCategory = 'all';

  final List<Map<String, dynamic>> _providers = [
    {
      'id': 'em-1',
      'name': 'سطحة كوردستان للإنقاذ السريع',
      'type': 'towing',
      'typeLabel': 'سطحة وإنقاذ',
      'phone': '07501112233',
      'coverage': 'أربيل، طريق دهوك، طريق شقلاوة',
      'distanceKm': 2.4,
      'isAvailable24': true,
      'rating': 4.9,
    },
    {
      'id': 'em-2',
      'name': 'بنجرجي متنقل السريع',
      'type': 'tire',
      'typeLabel': 'بنجرجي متنقل',
      'phone': '07509871122',
      'coverage': 'أربيل - شارع 100 متري و 120 متري',
      'distanceKm': 1.2,
      'isAvailable24': true,
      'rating': 4.8,
    },
    {
      'id': 'em-3',
      'name': 'خدمة تبديل وشحن البطاريات على الطريق',
      'type': 'battery',
      'typeLabel': 'بطارية وكهرباء',
      'phone': '07504445566',
      'coverage': 'أربيل وضواحيها',
      'distanceKm': 3.1,
      'isAvailable24': true,
      'rating': 4.7,
    },
    {
      'id': 'em-4',
      'name': 'ميكانيك وطوارئ سيارات على الطريق',
      'type': 'mechanic',
      'typeLabel': 'ميكانيكي سيارات',
      'phone': '07503338899',
      'coverage': 'أربيل - المنطقة الصناعية وطريق دهوك',
      'distanceKm': 4.5,
      'isAvailable24': false,
      'rating': 4.6,
    },
  ];

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _selectedCategory == 'all'
        ? _providers
        : _providers.where((p) => p['type'] == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('أحتاج مساعدة / خدمات السيارات'),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('all', 'الكل', null),
                const SizedBox(width: 8),
                _buildFilterChip('towing', 'سطحة وإنقاذ', DarbIconType.brokenCar),
                const SizedBox(width: 8),
                _buildFilterChip('tire', 'بنجرجي متنقل', DarbIconType.tireRepair),
                const SizedBox(width: 8),
                _buildFilterChip('battery', 'بطارية وكهرباء', DarbIconType.battery),
                const SizedBox(width: 8),
                _buildFilterChip('mechanic', 'ميكانيكي سيارات', DarbIconType.workshop),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
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
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryEmerald.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DarbIcon(_getProviderIcon(p['type'] as String), color: AppTheme.primaryEmerald, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p['name'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    p['typeLabel'],
                                    style: TextStyle(
                                      color: isDark ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
                                      fontSize: 13,
                                      
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.secondarySand.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${p['distanceKm']} كم',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.place_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                p['coverage'],
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                            if (p['isAvailable24'])
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.successGreen.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'طوارئ 24/7',
                                  style: TextStyle(color: AppTheme.successGreen, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Large Call Button
                        DriverSafeButton(
                          label: 'اتصال فوري: ${p['phone']}',
                          icon: Icons.phone_in_talk_rounded,
                          height: 48,
                          onPressed: () => _makeCall(p['phone']),
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

  DarbIconType _getProviderIcon(String type) {
    switch (type) {
      case 'towing':
        return DarbIconType.brokenCar;
      case 'tire':
        return DarbIconType.tireRepair;
      case 'battery':
        return DarbIconType.battery;
      case 'mechanic':
      default:
        return DarbIconType.workshop;
    }
  }

  Widget _buildFilterChip(String key, String label, DarbIconType? icon) {
    final isSelected = _selectedCategory == key;
    return ChoiceChip(
      avatar: icon != null
          ? DarbIcon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : AppTheme.primaryEmerald,
            )
          : null,
      label: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : null,
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.primaryEmerald,
      onSelected: (selected) {
        if (selected) setState(() => _selectedCategory = key);
      },
    );
  }
}
