import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_state.dart';
import '../core/theme/darb_icons.dart';

enum WazePinType { police, hazard, radar, traffic, accident, mood }

/// Backward-compatible wrapper delegating to DarbReportMarker
class WazePinWidget extends StatelessWidget {
  final RoadReportModel? report;
  final WazePinType? overrideType;
  final String? label;
  final VoidCallback? onTap;
  final double size;

  const WazePinWidget({
    super.key,
    this.report,
    this.overrideType,
    this.label,
    this.onTap,
    this.size = 38.0,
  });

  DarbIconType? get _mappedIconType {
    if (overrideType != null) {
      switch (overrideType!) {
        case WazePinType.police:
          return DarbIconType.checkpoint;
        case WazePinType.radar:
          return DarbIconType.radar;
        case WazePinType.traffic:
          return DarbIconType.traffic;
        case WazePinType.accident:
          return DarbIconType.accident;
        case WazePinType.hazard:
          return DarbIconType.danger;
        case WazePinType.mood:
          return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (overrideType == WazePinType.mood) {
      // Clean Community Driver Indicator (Replaces cartoon smiling car with clean DARB beacon)
      return Container(
        width: size * 0.8,
        height: size * 0.8,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          shape: BoxShape.circle,
          border: Border.all(color: DarbIconColors.emerald, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: DarbIcon(
            DarbIconType.myLocation,
            size: 16,
            color: DarbIconColors.emerald,
          ),
        ),
      );
    }

    return DarbReportMarker(
      report: report,
      overrideType: _mappedIconType,
      size: size,
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else if (report != null) {
          _showReportDetails(context);
        }
      },
    );
  }

  void _showReportDetails(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = appState.currentLanguage;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 16)],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  DarbReportMarker(
                    report: report,
                    overrideType: _mappedIconType,
                    size: 36,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getReportTitle(report!.type, lang),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report!.roadName,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (report!.description.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    report!.description,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DarbIconColors.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.thumb_up_alt_rounded, size: 18),
                      label: Text(
                        lang == 'en' ? 'Still There' : (lang == 'ku' ? 'هێشتا هەیە' : 'موجود 👍'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        appState.confirmReport(report!.id, 'CONFIRM');
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(lang == 'en' ? 'Thank you for confirming!' : (lang == 'ku' ? 'سوپاس بۆ پشتڕاستکردنەوە!' : 'شكراً لتأكيدك! ساعدت السائقين')),
                            backgroundColor: DarbIconColors.emerald,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: BorderSide(color: Colors.grey.withOpacity(0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.thumb_down_alt_rounded, size: 18),
                      label: Text(
                        lang == 'en' ? 'Cleared' : (lang == 'ku' ? 'نەماوە' : 'غير موجود 👎'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        appState.confirmReport(report!.id, 'DENY');
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getReportTitle(String type, String lang) {
    switch (type.toUpperCase()) {
      case 'POLICE':
      case 'CHECKPOINT':
        return lang == 'en' ? 'Police Checkpoint' : (lang == 'ku' ? 'بازگەی پۆلیس / ئاسایش' : 'سيطرة أمنية / شرطة');
      case 'RADAR':
      case 'CAMERA':
        return lang == 'en' ? 'Speed Camera' : (lang == 'ku' ? 'کامێرای تیژڕەوی' : 'رادار سرعة / كاميرا');
      case 'HAZARD':
      case 'DANGER':
      case 'WARNING':
        return lang == 'en' ? 'Road Hazard' : (lang == 'ku' ? 'مەترسی لەسەر ڕێگا' : 'خطر / عائق على الطريق');
      case 'TRAFFIC':
        return lang == 'en' ? 'Heavy Traffic' : (lang == 'ku' ? 'قەرەباڵغی هاتوچۆ' : 'ازدحام مروري خانق');
      case 'ACCIDENT':
        return lang == 'en' ? 'Traffic Accident' : (lang == 'ku' ? 'ڕووداوی هاتوچۆ' : 'حادث سير');
      case 'POTHOLE':
        return lang == 'en' ? 'Pothole / Road Damage' : (lang == 'ku' ? 'چاڵ لەسەر شەقام' : 'حفرة / تخسف في الشارع');
      case 'CLOSURE':
        return lang == 'en' ? 'Road Closure' : (lang == 'ku' ? 'شەقام داخراوە' : 'طريق مغلق');
      case 'ROADWORKS':
        return lang == 'en' ? 'Road Works' : (lang == 'ku' ? 'کاری ڕێگاوبان' : 'أشغال طريق');
      case 'FLOOD':
        return lang == 'en' ? 'Flooding / Water' : (lang == 'ku' ? 'کۆبوونەوەی ئاو' : 'تجمع مياه');
      default:
        return lang == 'en' ? 'Road Alert' : (lang == 'ku' ? 'ئاگاداری ڕێگا' : 'تنبيه على الطريق');
    }
  }
}
