import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/darb_icons.dart';
import '../../shared_widgets/darb_card.dart';
import '../../shared_widgets/darb_button.dart';

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
    final uri = Uri.parse('tel:');
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
        title: Text('أحتاج مساعدة', style: DarbTypography.title),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: DarbSpacing.lg, vertical: DarbSpacing.sm),
            child: Row(
              children: [
                _buildFilterChip('all', 'الكل', null),
                const SizedBox(width: DarbSpacing.sm),
                _buildFilterChip('towing', 'سطحة وإنقاذ', DarbIconType.brokenCar),
                const SizedBox(width: DarbSpacing.sm),
                _buildFilterChip('tire', 'بنجرجي متنقل', DarbIconType.tireRepair),
                const SizedBox(width: DarbSpacing.sm),
                _buildFilterChip('battery', 'بطارية وكهرباء', DarbIconType.battery),
                const SizedBox(width: DarbSpacing.sm),
                _buildFilterChip('mechanic', 'ميكانيكي سيارات', DarbIconType.workshop),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: DarbSpacing.lg, vertical: DarbSpacing.sm),
              itemCount: filtered.length,
              itemBuilder: (ctx, idx) {
                final p = filtered[idx];

                return Padding(
                  padding: const EdgeInsets.only(bottom: DarbSpacing.md),
                  child: DarbCard(
                    padding: const EdgeInsets.all(DarbSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(DarbSpacing.sm),
                              decoration: BoxDecoration(
                                color: DarbColors.primaryEmerald.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DarbIcon(_getProviderIcon(p['type'] as String), color: DarbColors.primaryEmerald, size: 24),
                            ),
                            const SizedBox(width: DarbSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p['name'],
                                    style: DarbTypography.section,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    p['typeLabel'],
                                    style: DarbTypography.caption,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: DarbSpacing.sm, vertical: DarbSpacing.xs),
                              decoration: BoxDecoration(
                                color: DarbColors.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: DarbColors.border.withOpacity(0.3)),
                              ),
                              child: Text(
                                ' كم',
                                style: DarbTypography.label.copyWith(color: DarbColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: DarbSpacing.md),
                        Row(
                          children: [
                            const DarbIcon(DarbIconType.info, size: 14, color: DarbColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                p['coverage'],
                                style: DarbTypography.caption,
                              ),
                            ),
                            if (p['isAvailable24'])
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: DarbSpacing.sm, vertical: 2),
                                decoration: BoxDecoration(
                                  color: DarbColors.successGreen.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'طوارئ 24/7',
                                  style: DarbTypography.label.copyWith(color: DarbColors.successGreen),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: DarbSpacing.lg),

                        // Large Call Button
                        DarbButton(
                          text: 'اتصال فوري: ',
                          icon: DarbIconType.phone,
                          size: DarbButtonSize.large,
                          isFullWidth: true,
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
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = key);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: DarbSpacing.md, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? DarbColors.primaryEmerald : DarbColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? DarbColors.primaryEmerald : DarbColors.border.withOpacity(0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              DarbIcon(
                icon,
                size: 16,
                color: isSelected ? DarbColors.textInversePrimary : DarbColors.primaryEmerald,
              ),
              const SizedBox(width: DarbSpacing.xs),
            ],
            Text(
              label,
              style: DarbTypography.bodyMedium.copyWith(
                color: isSelected ? DarbColors.textInversePrimary : DarbColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
