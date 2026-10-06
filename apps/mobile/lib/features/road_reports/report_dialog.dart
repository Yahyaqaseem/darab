import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/darb_icons.dart';

class ReportDialog extends StatefulWidget {
  const ReportDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ReportDialog(),
    );
  }

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  bool _isSubmitted = false;

  void _submitReport(BuildContext context, String type) async {
    setState(() { _isSubmitted = true; });
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.submitReport(type);
    
    await Future.delayed(const Duration(milliseconds: 1500));
    if (context.mounted && Navigator.canPop(context)) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? DarbColors.background : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 24),
          
          if (_isSubmitted) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: DarbColors.successGreen.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: DarbColors.successGreen, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text('تم إرسال البلاغ', style: DarbTypography.title.copyWith(color: DarbColors.successGreen)),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                const DarbIcon(DarbIconType.quickReport, color: DarbColors.warningOrange, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('إضافة بلاغ', style: DarbTypography.title.copyWith(color: isDark ? Colors.white : Colors.black, fontSize: 20)),
                    Text('سيظهر البلاغ على الخريطة للسائقين الآخرين', style: DarbTypography.caption.copyWith(color: DarbColors.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.start,
              children: [
                _buildReportButton('حادث', 'ACCIDENT', DarbIconType.accident, const Color(0xFFEF4444), isDark),
                _buildReportButton('زحام', 'TRAFFIC', DarbIconType.traffic, const Color(0xFFF59E0B), isDark),
                _buildReportButton('إغلاق', 'CLOSURE', DarbIconType.closure, const Color(0xFFEF4444), isDark),
                _buildReportButton('سيارة متعطلة', 'BROKEN_CAR', DarbIconType.brokenCar, const Color(0xFF8B5CF6), isDark),
                _buildReportButton('حفر', 'POTHOLE', DarbIconType.pothole, const Color(0xFFD97706), isDark),
                _buildReportButton('خطر', 'HAZARD', DarbIconType.danger, const Color(0xFFEAB308), isDark),
                _buildReportButton('مياه', 'FLOOD', DarbIconType.flood, const Color(0xFF06B6D4), isDark),
                _buildReportButton('سيطرة', 'CHECKPOINT', DarbIconType.checkpoint, const Color(0xFF3B82F6), isDark),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReportButton(String title, String type, DarbIconType icon, Color color, bool isDark) {
    final width = (MediaQuery.of(context).size.width - 52) / 2;
    return InkWell(
      onTap: () => _submitReport(context, type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? DarbColors.surface : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: DarbIcon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: DarbTypography.body.copyWith(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
