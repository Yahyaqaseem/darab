import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/darb_icons.dart';
import '../../shared_widgets/darb_card.dart';

class ReportDialog extends StatefulWidget {
  const ReportDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ReportDialog(),
    );
  }

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _descController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submit(String type) async {
    setState(() => _isSubmitting = true);
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.submitReport(type, description: _descController.text.trim());
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const DarbIcon(DarbIconType.verified, color: Colors.white, size: 24),
              const SizedBox(width: DarbSpacing.sm),
              Expanded(
                child: Text(
                  'تم نشر البلاغ لجميع السائقين على الطريق (+10 نقاط سمعة)',
                  style: DarbTypography.body.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: DarbColors.primaryEmerald,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  DarbIconType _getReportIcon(String type) {
    switch (type) {
      case 'ACCIDENT':
        return DarbIconType.accident;
      case 'HEAVY_TRAFFIC':
        return DarbIconType.traffic;
      case 'CHECKPOINT':
        return DarbIconType.checkpoint;
      case 'CLOSURE':
        return DarbIconType.closure;
      case 'POTHOLE':
        return DarbIconType.pothole;
      case 'WATER_ACCUMULATION':
        return DarbIconType.flood;
      case 'DETOUR':
        return DarbIconType.route;
      case 'BROKEN_CAR':
        return DarbIconType.brokenCar;
      case 'ROADWORKS':
        return DarbIconType.roadworks;
      case 'DANGER':
        return DarbIconType.danger;
      case 'BAD_ROAD':
        return DarbIconType.badRoad;
      case 'OTHER':
      default:
        return DarbIconType.otherReport;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DarbSpacing.xl, vertical: DarbSpacing.xxl),
      decoration: BoxDecoration(
        color: DarbColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: DarbColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: DarbSpacing.lg),
            Row(
              children: [
                const DarbIcon(DarbIconType.quickReport, color: DarbColors.dangerRed, size: 26),
                const SizedBox(width: DarbSpacing.sm),
                Text(
                  'إبلاغ فوري عن حالة الطريق',
                  style: DarbTypography.title,
                ),
              ],
            ),
            const SizedBox(height: DarbSpacing.xs),
            Text(
              'اختر نوع الحدث بضغطة واحدة ليظهر فوراً للسائقين المتجهين لنفس المسار:',
              style: DarbTypography.body.copyWith(color: DarbColors.textSecondary),
            ),
            const SizedBox(height: DarbSpacing.xl),

            // 1-Tap Grid of Incident Buttons
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.3,
                crossAxisSpacing: DarbSpacing.sm,
                mainAxisSpacing: DarbSpacing.sm,
              ),
              itemCount: AppConstants.reportTypes.length,
              itemBuilder: (ctx, idx) {
                final item = AppConstants.reportTypes[idx];
                final color = item['color'] as Color;

                return Material(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: _isSubmitting ? null : () => _submit(item['type']),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: DarbSpacing.sm, vertical: DarbSpacing.sm),
                      decoration: BoxDecoration(
                        border: Border.all(color: color.withOpacity(0.35), width: 1.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(DarbSpacing.xs),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: DarbIcon(_getReportIcon(item['type'] as String), color: color, size: 20),
                          ),
                          const SizedBox(width: DarbSpacing.xs),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item['label'],
                                  style: DarbTypography.body.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: DarbSpacing.md),
          ],
        ),
      ),
    );
  }
}
