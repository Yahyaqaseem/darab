import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
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
      builder: (context) => const ReportDialog(),
    );
  }

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> with SingleTickerProviderStateMixin {
  bool _isSubmitted = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  final int _nearbyDrivers = Random().nextInt(40) + 5; // Simulated nearby drivers for UX

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnimation = CurvedAnimation(parent: _animController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _submitCall(BuildContext context, String type) async {
    setState(() { _isSubmitted = true; });
    _animController.forward();
    
    // Actually submit the report via appState
    final appState = Provider.of<AppState>(context, listen: false);
    appState.submitReport(type, description: 'User call');
    
    await Future.delayed(const Duration(milliseconds: 1500));
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = Provider.of<AppState>(context).currentLanguage;

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
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          if (_isSubmitted) ...[
            SizedBox(
              height: 300,
              child: Center(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: DarbColors.successGreen.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: DarbColors.successGreen, size: 80),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        lang == 'ku' ? 'بانگەوازەکەت نێردرا!' : (lang == 'en' ? 'Call sent successfully!' : 'تم إرسال النداء للسائقين!'),
                        style: DarbTypography.title.copyWith(color: isDark ? Colors.white : Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const DarbIcon(DarbIconType.roadCall, color: DarbColors.primaryYellow, size: 28),
                const SizedBox(width: 12),
                Text(
                  lang == 'ku' ? 'بانگەوازی ڕێگا' : (lang == 'en' ? 'Road Call' : 'نداء الطريق'),
                  style: DarbTypography.display.copyWith(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: DarbColors.primaryYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DarbColors.primaryYellow.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.radar, color: DarbColors.primaryYellow, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    lang == 'ku' ? ' شۆفێر لە نزیکتن' : (lang == 'en' ? ' drivers nearby' : ' سائقين بالقرب منك على نفس المسار'),
                    style: DarbTypography.body.copyWith(color: DarbColors.primaryYellow, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              lang == 'ku' ? 'دەتەوێت پرسیار لە شۆفێران بکەیت دەربارەی چی؟' : (lang == 'en' ? 'What do you want to ask drivers about?' : 'عن ماذا تريد أن تسأل السائقين؟'),
              style: DarbTypography.body.copyWith(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildCallButton(context, 'ACCIDENT', 'هل يوجد حادث؟', 'ڕووداو هەیە؟', Icons.car_crash, const Color(0xFFEF4444)),
                    _buildCallButton(context, 'TRAFFIC', 'هل الطريق مزدحم؟', 'قەرەباڵغییە؟', Icons.traffic, const Color(0xFFF59E0B)),
                    _buildCallButton(context, 'CHECKPOINT', 'نقطة تفتيش؟', 'بازگە هەیە؟', Icons.security, const Color(0xFF3B82F6)),
                    _buildCallButton(context, 'POTHOLE', 'توجد حفرة/تخسف؟', 'چاڵ هەیە؟', Icons.warning, const Color(0xFFCA8A04)),
                    _buildCallButton(context, 'HAZARD', 'يوجد خطر بالطريق؟', 'مەترسی هەیە؟', Icons.warning_amber, const Color(0xFF8B5CF6)),
                    _buildCallButton(context, 'POLICE', 'يوجد مرور/شرطة؟', 'پۆلیس هەیە؟', Icons.local_police, const Color(0xFF0EA5E9)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCallButton(BuildContext context, String type, String titleAr, String titleKu, IconData icon, Color color) {
    final lang = Provider.of<AppState>(context, listen: false).currentLanguage;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: () => _submitCall(context, type),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: (MediaQuery.of(context).size.width - 60) / 2,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? DarbColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              lang == 'ku' ? titleKu : (lang == 'en' ? titleAr : titleAr),
              textAlign: TextAlign.center,
              style: DarbTypography.body.copyWith(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
