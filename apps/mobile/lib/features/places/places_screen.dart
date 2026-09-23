import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../navigation/navigation_screen.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/darb_icons.dart';
import '../../shared_widgets/darb_card.dart';
import '../../shared_widgets/darb_button.dart';

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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('دليل الأماكن والخدمات', style: DarbTypography.title),
      ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DarbSpacing.lg, vertical: DarbSpacing.sm),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: DarbTypography.body,
              decoration: InputDecoration(
                hintText: 'ابحث عن مكان، ورشة، مطعم...',
                hintStyle: DarbTypography.body.copyWith(color: DarbColors.textSecondary),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(DarbSpacing.md),
                  child: DarbIcon(DarbIconType.search, size: 20, color: DarbColors.textSecondary),
                ),
                filled: true,
                fillColor: isDark ? DarbColors.surface : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16), 
                  borderSide: BorderSide(color: DarbColors.border.withOpacity(0.5))
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16), 
                  borderSide: BorderSide(color: DarbColors.border.withOpacity(0.5))
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16), 
                  borderSide: const BorderSide(color: DarbColors.primaryEmerald)
                ),
              ),
            ),
          ),

          // Categories Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: DarbSpacing.lg, vertical: DarbSpacing.xs),
            child: Row(
              children: [
                _buildCatChip('all', 'الكل', null),
                const SizedBox(width: DarbSpacing.sm),
                _buildCatChip('tire_repair', 'بنجرجية', DarbIconType.tireRepair),
                const SizedBox(width: DarbSpacing.sm),
                _buildCatChip('mechanic', 'ورش وميكانيك', DarbIconType.workshop),
                const SizedBox(width: DarbSpacing.sm),
                _buildCatChip('towing', 'سطحة وإنقاذ', DarbIconType.brokenCar),
                const SizedBox(width: DarbSpacing.sm),
                _buildCatChip('restaurant', 'مطاعم', DarbIconType.restaurant),
                const SizedBox(width: DarbSpacing.sm),
                _buildCatChip('cafe', 'كافيهات', DarbIconType.cafe),
              ],
            ),
          ),
          const SizedBox(height: DarbSpacing.sm),

          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text('لا توجد أماكن مطابقة', style: DarbTypography.body))
                : ListView.builder(
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
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.nameAr,
                                          style: DarbTypography.section,
                                        ),
                                        const SizedBox(height: DarbSpacing.xs),
                                        Text(
                                          p.address,
                                          style: DarbTypography.caption,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: DarbSpacing.sm, vertical: DarbSpacing.xs),
                                    decoration: BoxDecoration(
                                      color: DarbColors.warningOrange.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const DarbIcon(DarbIconType.starFilled, color: DarbColors.warningOrange, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          p.rating.toString(),
                                          style: DarbTypography.numeric.copyWith(color: DarbColors.warningOrange),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: DarbSpacing.md),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const DarbIcon(DarbIconType.info, size: 14, color: DarbColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(p.openingHours, style: DarbTypography.caption),
                                    ],
                                  ),
                                  if (p.distanceKm != null)
                                    Text(
                                      ' كم من موقعك',
                                      style: DarbTypography.label.copyWith(color: DarbColors.primaryEmerald),
                                    ),
                                ],
                              ),
                              const SizedBox(height: DarbSpacing.md),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: DarbButton(
                                      text: 'اذهب إليه',
                                      icon: DarbIconType.route,
                                      size: DarbButtonSize.small,
                                      isFullWidth: true,
                                      onPressed: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => NavigationScreen(destinationName: p.nameAr, destLat: p.latitude, destLng: p.longitude,)));
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: DarbSpacing.sm),
                                  Expanded(
                                    flex: 1,
                                    child: DarbButton(
                                      text: 'اتصال',
                                      icon: DarbIconType.phone,
                                      variant: DarbButtonVariant.secondary,
                                      size: DarbButtonSize.small,
                                      isFullWidth: true,
                                      onPressed: () {},
                                    ),
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

  Widget _buildCatChip(String key, String label, DarbIconType? icon) {
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
