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
      decoration: BoxDecoration(
        color: isDark ? DarbColors.background : Colors.white,
        border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12, width: 1)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 8, top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildItem(0, DarbIconType.home, 'الخريطة', context),
          _buildItem(1, DarbIconType.quickReport, 'البلاغات', context),
          _buildItem(2, DarbIconType.fuel, 'الوقود', context),
          _buildItem(3, DarbIconType.workshop, 'الخدمات', context),
          _buildItem(4, DarbIconType.profile, 'حسابي', context),
        ],
      ),
    );
  }

  Widget _buildItem(int index, DarbIconType icon, String label, BuildContext context) {
    final isSelected = currentIndex == index;
    final color = isSelected ? DarbColors.primaryYellow : DarbColors.textDisabled;
    
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTabSelected(index),
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 5,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DarbIcon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: DarbTypography.caption.copyWith(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
