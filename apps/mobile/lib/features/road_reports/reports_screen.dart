import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/darb_icons.dart';
import '../../shared_widgets/darb_card.dart';
import '../../shared_widgets/darb_button.dart';
import 'report_dialog.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final reports = appState.reports;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('بلاغات الطريق الحية', style: DarbTypography.title),
        actions: [
          IconButton(
            icon: const DarbIcon(DarbIconType.refresh, size: 24, color: DarbColors.primaryEmerald),
            onPressed: () => appState.loadNearbyData(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: DarbColors.dangerRed,
        foregroundColor: Colors.white,
        icon: const DarbIcon(DarbIconType.danger, color: Colors.white, size: 20),
        label: Text('إبلاغ جديد', style: DarbTypography.section.copyWith(color: Colors.white)),
        onPressed: () => ReportDialog.show(context),
      ),
      body: reports.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DarbIcon(DarbIconType.verified, size: 64, color: DarbColors.successGreen.withOpacity(0.6)),
                  const SizedBox(height: DarbSpacing.md),
                  Text('الطرق سالكة ولا توجد بلاغات حالياً', style: DarbTypography.section),
                  const SizedBox(height: DarbSpacing.xs),
                  Text(
                    'كن أول من يبلغ إذا صادفك أي عائق أو ازدحام',
                    style: DarbTypography.body.copyWith(color: DarbColors.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: DarbSpacing.lg, vertical: DarbSpacing.sm),
              itemCount: reports.length,
              itemBuilder: (ctx, idx) {
                final r = reports[idx];
                final remainingMins = r.expiresAt.difference(DateTime.now()).inMinutes;

                // Simple icon mapping since we lack the old material icon
                DarbIconType rIcon = DarbIconType.danger;
                if (r.type.contains('ACCIDENT')) rIcon = DarbIconType.accident;
                if (r.type.contains('TRAFFIC')) rIcon = DarbIconType.traffic;

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
                                color: r.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DarbIcon(rIcon, color: r.color, size: 24),
                            ),
                            const SizedBox(width: DarbSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.title, style: DarbTypography.section),
                                  const SizedBox(height: 2),
                                  Text(r.roadName, style: DarbTypography.caption),
                                ],
                              ),
                            ),
                            if (r.distanceMeters != null) ...[
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
                          ],
                        ),
                        if (r.description.isNotEmpty) ...[
                          const SizedBox(height: DarbSpacing.sm),
                          Text(r.description, style: DarbTypography.body),
                        ],
                        const SizedBox(height: DarbSpacing.md),
                        const Divider(height: 1, color: DarbColors.border),
                        const SizedBox(height: DarbSpacing.md),

                        // Stats & Confidence
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const DarbIcon(DarbIconType.verified, size: 16, color: DarbColors.primaryEmerald),
                                const SizedBox(width: DarbSpacing.xs),
                                Text(
                                  ' سواق أكدوا',
                                  style: DarbTypography.label.copyWith(color: DarbColors.primaryEmerald),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const DarbIcon(DarbIconType.info, size: 14, color: DarbColors.textSecondary),
                                const SizedBox(width: DarbSpacing.xs),
                                Text(
                                  remainingMins > 0 ? 'ينتهي بعد  د' : 'أوشك على الانتهاء',
                                  style: DarbTypography.caption,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: DarbSpacing.lg),

                        // Confirm / Reject Voting Bar
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: DarbButton(
                                text: 'تأكيد البلاغ',
                                icon: DarbIconType.verified,
                                size: DarbButtonSize.small,
                                isFullWidth: true,
                                onPressed: () => appState.confirmReport(r.id, 'CONFIRM'),
                              ),
                            ),
                            const SizedBox(width: DarbSpacing.sm),
                            Expanded(
                              flex: 1,
                              child: DarbButton(
                                text: 'غير موجود',
                                variant: DarbButtonVariant.danger,
                                size: DarbButtonSize.small,
                                isFullWidth: true,
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
