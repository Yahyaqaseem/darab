import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../../core/providers/app_state.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/darb_icons.dart';
import '../navigation/navigation_screen.dart';

class FuelScreen extends StatelessWidget {
  const FuelScreen({super.key});

  String _getTimeAgo(DateTime time, String lang) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return lang == 'ku' ? 'پێش ${diff.inMinutes} خولەک' : 'قبل ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return lang == 'ku' ? 'پێش ${diff.inHours} کاتژمێر' : 'قبل ${diff.inHours} ساعة';
    return lang == 'ku' ? 'پێش ${diff.inDays} ڕۆژ' : 'منذ ${diff.inDays} يوم';
  }

  Widget _getFreshnessIndicator(DateTime time, String lang) {
    final diff = DateTime.now().difference(time);
    Color color;
    if (diff.inHours < 2) color = DarbColors.successGreen;
    else if (diff.inHours < 24) color = DarbColors.warningOrange;
    else color = DarbColors.textDisabled;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, color: color, size: 8),
        const SizedBox(width: 4),
        Text(
          _getTimeAgo(time, lang),
          style: DarbTypography.caption.copyWith(color: DarbColors.textSecondary),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final stations = appState.fuelStations;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? DarbColors.background : const Color(0xFFF8FAFC);
    final surfaceColor = isDark ? DarbColors.surface : Colors.white;
    final textColor = isDark ? DarbColors.textPrimary : DarbColors.textInversePrimary;
    final lang = appState.currentLanguage;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('محطات الوقود', style: DarbTypography.title.copyWith(color: textColor)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: DarbColors.primaryYellow.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${stations.length} محطة',
                    style: DarbTypography.body.copyWith(
                      color: DarbColors.primaryYellow,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: stations.isEmpty
                ? Center(
                    child: Text(
                      'لا توجد محطات وقود قريبة',
                      style: DarbTypography.section.copyWith(color: DarbColors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: stations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final s = stations[index];
                      // Calculate distance if missing
                      double distanceKm = s.distanceKm ?? 0.0;
                      if (distanceKm == 0.0 && appState.currentLat != 0) {
                        final distM = const Distance().as(LengthUnit.Meter, LatLng(appState.currentLat, appState.currentLng), LatLng(s.latitude, s.longitude));
                        distanceKm = distM / 1000.0;
                      }

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            // Close bottom sheet if opened as a sheet
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                            Navigator.push(context, MaterialPageRoute(builder: (_) => NavigationScreen(
                              destinationName: s.nameAr,
                              destLat: s.latitude,
                              destLng: s.longitude,
                            )));
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icon Column
                                Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: DarbColors.surface,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                                      ),
                                      child: const DarbIcon(DarbIconType.fuel, color: DarbColors.primaryYellow, size: 24),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                
                                // Info Column
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.nameAr,
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
                                          Text(
                                            '${distanceKm.toStringAsFixed(1)} km',
                                            style: DarbTypography.caption.copyWith(
                                              color: DarbColors.textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          _getFreshnessIndicator(s.priceUpdatedAt, lang),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      
                                      // Quality/Crowd Tags
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: s.crowdColor.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              s.crowdText,
                                              style: DarbTypography.caption.copyWith(
                                                color: s.crowdColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Price Column
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      s.petrolPrice > 0 ? '${s.petrolPrice}' : 'غير متوفر',
                                      style: DarbTypography.numeric.copyWith(
                                        color: s.petrolPrice > 0 ? textColor : DarbColors.textDisabled,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (s.petrolPrice > 0)
                                      Text(
                                        'IQD/L',
                                        style: DarbTypography.caption.copyWith(
                                          color: DarbColors.primaryYellow,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'بنزين عادي',
                                      style: DarbTypography.caption.copyWith(
                                        color: DarbColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.navigation, color: DarbColors.primaryYellow, size: 24),
                              ],
                            ),
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
}
