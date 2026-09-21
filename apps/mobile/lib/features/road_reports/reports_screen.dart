import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../shared_widgets/incident_badge.dart';
import 'report_dialog.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final reports = appState.reports;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('بلاغات الطريق الحية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => appState.loadNearbyData(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.alertRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text(
          'إبلاغ جديد',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
        ),
        onPressed: () => ReportDialog.show(context),
      ),
      body: reports.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: AppTheme.successGreen.withOpacity(0.6)),
                  const SizedBox(height: 16),
                  const Text(
                    'الطرق سالكة ولا توجد بلاغات حالياً',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'كن أول من يبلغ إذا صادفك أي عائق أو ازدحام',
                    style: TextStyle(
                      color: isDark ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: reports.length,
              itemBuilder: (ctx, idx) {
                final r = reports[idx];
                final remainingMins = r.expiresAt.difference(DateTime.now()).inMinutes;

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
                                color: r.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(r.icon, color: r.color, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    r.roadName,
                                    style: TextStyle(
                                      color: isDark ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
                                      fontSize: 13,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (r.distanceMeters != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${(r.distanceMeters! / 1000).toStringAsFixed(1)} كم',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (r.description.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            r.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppTheme.textLightPrimary : AppTheme.textDarkPrimary,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 10),

                        // Stats & Confidence
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.people_alt_outlined, size: 18, color: AppTheme.primaryEmerald),
                                const SizedBox(width: 6),
                                Text(
                                  '${r.confirmationsCount} سواق أكدوا',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppTheme.primaryEmerald,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  remainingMins > 0 ? 'ينتهي بعد $remainingMins د' : 'أوشك على الانتهاء',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Cairo'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Confirm / Reject Voting Bar
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryEmerald.withOpacity(0.12),
                                  foregroundColor: AppTheme.primaryEmerald,
                                  elevation: 0,
                                  minimumSize: const Size(0, 42),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.check_circle_outline, size: 18),
                                label: const Text('تأكيد البلاغ', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                                onPressed: () => appState.confirmReport(r.id, 'CONFIRM'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.alertRed,
                                  side: BorderSide(color: AppTheme.alertRed.withOpacity(0.4)),
                                  minimumSize: const Size(0, 42),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('غير موجود', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                                onPressed: () => appState.confirmReport(r.id, 'NOT_THERE_ANYMORE'),
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
    );
  }
}
