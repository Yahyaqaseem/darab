import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_state.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/darb_icons.dart';
import 'report_dialog.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final reports = appState.reports;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text('البلاغات', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const DarbIcon(DarbIconType.refresh, size: 20),
            color: textColor,
            onPressed: () => appState.loadNearbyData(),
          ),
        ],
      ),
      body: reports.isEmpty
          ? Center(child: Text('لا توجد بلاغات قريبة', style: TextStyle(color: textColor)))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: reports.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final r = reports[index];
                return _buildReportItem(r, surfaceColor, textColor, isDark);
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: DarbColors.primaryYellow,
        child: const DarbIcon(DarbIconType.roadCall, color: Color(0xFF0F172A), size: 24),
        onPressed: () => ReportDialog.show(context),
      ),
    );
  }

  Widget _buildReportItem(RoadReportModel report, Color surfaceColor, Color textColor, bool isDark) {
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
              color: DarbColors.dangerRed.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded, color: DarbColors.dangerRed, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(report.roadName, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.thumb_up, size: 14, color: DarbColors.successGreen),
                    const SizedBox(width: 4),
                    Text('', style: const TextStyle(color: DarbColors.successGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),
                    const Icon(Icons.schedule, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    const Text('منذ 5 د', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
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
