import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/darb_icons.dart';

class DarbBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final bool isDark;

  const DarbBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? DarbColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, DarbIconType.home, 'الخريطة'),
            _buildNavItem(1, DarbIconType.quickReport, 'البلاغات'),
            _buildNavItem(2, DarbIconType.fuel, 'الوقود'),
            _buildNavItem(3, DarbIconType.workshop, 'الخدمات'),
            _buildNavItem(4, DarbIconType.profile, 'حسابي'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, DarbIconType icon, String label) {
    final isSelected = currentIndex == index;
    final color = isSelected
        ? DarbColors.primaryEmerald
        : (isDark ? DarbColors.textSecondary : DarbColors.textDisabled);

    return GestureDetector(
      onTap: () => onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? DarbColors.primaryEmerald.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DarbIcon(
              icon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
