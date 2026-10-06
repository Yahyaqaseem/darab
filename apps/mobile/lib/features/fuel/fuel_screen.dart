import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_state.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/darb_icons.dart';

class FuelScreen extends StatelessWidget {
  const FuelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final stations = appState.fuelStations;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text('محطات الوقود', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const DarbIcon(DarbIconType.search, size: 20),
            color: textColor,
            onPressed: () {},
          ),
        ],
      ),
      body: stations.isEmpty
          ? Center(child: Text('جاري تحميل المحطات...', style: TextStyle(color: textColor)))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: stations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final s = stations[index];
                return _buildStationItem(s, surfaceColor, textColor, isDark);
              },
            ),
    );
  }

  Widget _buildStationItem(FuelStationModel station, Color surfaceColor, Color textColor, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DarbColors.primaryYellow.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const DarbIcon(DarbIconType.fuel, color: DarbColors.primaryYellow, size: 24),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(station.nameAr, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('m • ', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              ],
            ),
          ),
          // Price Focus
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                station.petrolPrice != null ? ' IQD' : 'غير مسعر',
                style: TextStyle(color: DarbColors.primaryYellow, fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 2),
              const Text('عادي', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
