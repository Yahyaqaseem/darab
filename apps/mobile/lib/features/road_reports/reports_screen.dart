import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_state.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/darb_icons.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final reports = appState.reports;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? DarbColors.background : const Color(0xFFF8FAFC);
    final surfaceColor = isDark ? DarbColors.surface : Colors.white;
    final textColor = isDark ? DarbColors.textPrimary : DarbColors.textInversePrimary;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('البلاغات', style: DarbTypography.title.copyWith(color: textColor)),
                IconButton(
                  icon: const DarbIcon(DarbIconType.refresh, size: 20),
                  color: DarbColors.textSecondary,
                  onPressed: () => appState.loadNearbyData(),
                ),
              ],
            ),
          ),
          Expanded(
            child: reports.isEmpty
                ? Center(
                    child: Text('لا توجد بلاغات قريبة حالياً', style: DarbTypography.body.copyWith(color: DarbColors.textSecondary)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: reports.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final r = reports[index];
                      return _buildReportItem(context, r, surfaceColor, textColor, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  DarbIconType _getIconForReportType(String type) {
    switch (type) {
      case 'ACCIDENT': return DarbIconType.accident;
      case 'TRAFFIC': return DarbIconType.traffic;
      case 'CHECKPOINT': return DarbIconType.checkpoint;
      case 'POTHOLE': return DarbIconType.pothole;
      case 'CLOSURE': return DarbIconType.closure;
      case 'BROKEN_CAR': return DarbIconType.brokenCar;
      case 'FLOOD': return DarbIconType.flood;
      case 'HAZARD': return DarbIconType.danger;
      default: return DarbIconType.warning;
    }
  }

  Color _getColorForReportType(String type) {
    switch (type) {
      case 'ACCIDENT':
      case 'CLOSURE':
        return const Color(0xFFEF4444);
      case 'TRAFFIC':
        return const Color(0xFFF59E0B);
      case 'CHECKPOINT':
        return const Color(0xFF3B82F6);
      case 'POTHOLE':
        return const Color(0xFFD97706);
      case 'FLOOD':
        return const Color(0xFF06B6D4);
      default:
        return const Color(0xFFEAB308);
    }
  }

  Widget _buildReportItem(BuildContext context, RoadReportModel report, Color surfaceColor, Color textColor, bool isDark) {
    final iconType = _getIconForReportType(report.type);
    final iconColor = _getColorForReportType(report.type);
    final appState = Provider.of<AppState>(context, listen: false);
    final hasVoted = appState.hasVotedOnReport(report.id);
    
    final timeDiff = DateTime.now().difference(report.createdAt);
    String timeStr = '${timeDiff.inMinutes} د';
    if (timeDiff.inHours > 0) timeStr = '${timeDiff.inHours} س';

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: DarbIcon(iconType, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.title, style: DarbTypography.body.copyWith(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(report.roadName, style: DarbTypography.caption.copyWith(color: DarbColors.textSecondary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (hasVoted) ...[
                      const DarbIcon(DarbIconType.verified, color: DarbColors.successGreen, size: 16),
                      const SizedBox(width: 4),
                      Text('✓ تم التأكيد', style: DarbTypography.caption.copyWith(color: DarbColors.successGreen, fontWeight: FontWeight.bold)),
                    ] else ...[
                      GestureDetector(
                        onTap: () {
                          appState.confirmReport(report.id, 'CONFIRM');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? DarbColors.background : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                          ),
                          child: Row(
                            children: [
                              const DarbIcon(DarbIconType.verified, color: DarbColors.textSecondary, size: 14),
                              const SizedBox(width: 4),
                              Text('تأكيد البلاغ', style: DarbTypography.caption.copyWith(color: DarbColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 16),
                    Text('•', style: DarbTypography.caption.copyWith(color: DarbColors.textSecondary)),
                    const SizedBox(width: 8),
                    Text('منذ $timeStr', style: DarbTypography.caption.copyWith(color: DarbColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
