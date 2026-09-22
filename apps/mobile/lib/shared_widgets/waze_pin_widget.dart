import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_theme.dart';

enum WazePinType { police, hazard, radar, traffic, accident, mood }

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

  WazePinType get pinType {
    if (overrideType != null) return overrideType!;
    if (report == null) return WazePinType.hazard;
    final t = report!.type.toUpperCase();
    if (t.contains('POLICE')) return WazePinType.police;
    if (t.contains('RADAR') || t.contains('CAMERA')) return WazePinType.radar;
    if (t.contains('TRAFFIC') || t.contains('JAM')) return WazePinType.traffic;
    if (t.contains('ACCIDENT') || t.contains('CRASH')) return WazePinType.accident;
    return WazePinType.hazard;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else if (report != null) {
          _showReportDetails(context);
        }
      },
      child: CustomPaint(
        size: Size(size, size * 1.15),
        painter: _WazePinPainter(pinType),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: _buildPinIcon(),
          ),
        ),
      ),
    );
  }

  Widget _buildPinIcon() {
    switch (pinType) {
      case WazePinType.police:
        return Container(
          width: size * 0.65,
          height: size * 0.65,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF0284C7),
          ),
          child: const Icon(
            Icons.local_police_rounded,
            color: Colors.white,
            size: 17,
          ),
        );

      case WazePinType.radar:
        return Container(
          width: size * 0.65,
          height: size * 0.65,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF0EA5E9),
          ),
          child: const Icon(
            Icons.camera_alt_rounded,
            color: Colors.white,
            size: 16,
          ),
        );

      case WazePinType.hazard:
        return Container(
          width: size * 0.65,
          height: size * 0.65,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFF59E0B),
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.black87,
            size: 18,
          ),
        );

      case WazePinType.traffic:
        return Container(
          width: size * 0.65,
          height: size * 0.65,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFEF4444),
          ),
          child: const Icon(
            Icons.directions_car_rounded,
            color: Colors.white,
            size: 16,
          ),
        );

      case WazePinType.accident:
        return Container(
          width: size * 0.65,
          height: size * 0.65,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFDC2626),
          ),
          child: const Icon(
            Icons.car_crash_rounded,
            color: Colors.white,
            size: 16,
          ),
        );

      case WazePinType.mood:
        return Container(
          width: size * 0.82,
          height: size * 0.82,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF43F5E),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: const Center(
            child: Icon(
              Icons.sentiment_very_satisfied_rounded,
              color: Colors.white,
              size: 19,
            ),
          ),
        );
    }
  }

  void _showReportDetails(BuildContext context) {
    if (report == null) return;
    final appState = Provider.of<AppState>(context, listen: false);
    final lang = appState.currentLanguage;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 16)],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  WazePinWidget(report: report, size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getReportTitle(report!.type, lang),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report!.roadName,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryEmerald.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ' تأكيد',
                      style: const TextStyle(
                        color: AppTheme.primaryEmerald,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
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
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryEmerald,
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
                            backgroundColor: AppTheme.primaryEmerald,
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
        return lang == 'en' ? 'Police Checkpoint' : (lang == 'ku' ? 'بازگەی پۆلیس / ئاسایش' : 'سيطرة أمنية / شرطة');
      case 'RADAR':
      case 'CAMERA':
        return lang == 'en' ? 'Speed Camera' : (lang == 'ku' ? 'کامێرای تیژڕەوی' : 'رادار سرعة / كاميرا');
      case 'HAZARD':
      case 'WARNING':
        return lang == 'en' ? 'Road Hazard' : (lang == 'ku' ? 'مەترسی لەسەر ڕێگا' : 'خطر / عائق على الطريق');
      case 'TRAFFIC':
        return lang == 'en' ? 'Heavy Traffic' : (lang == 'ku' ? 'قەرەباڵغی هاتوچۆ' : 'ازدحام مروري خانق');
      case 'ACCIDENT':
        return lang == 'en' ? 'Traffic Accident' : (lang == 'ku' ? 'ڕووداوی هاتوچۆ' : 'حادث سير');
      default:
        return lang == 'en' ? 'Road Alert' : (lang == 'ku' ? 'ئاگاداری ڕێگا' : 'تنبيه على الطريق');
    }
  }
}

class _WazePinPainter extends CustomPainter {
  final WazePinType type;

  _WazePinPainter(this.type);

  @override
  void paint(Canvas canvas, Size size) {
    if (type == WazePinType.mood) return;

    final w = size.width;
    final h = size.height;
    final radius = w * 0.48;
    final centerX = w * 0.5;
    final centerY = radius;

    final path = Path();
    path.addOval(Rect.fromCircle(center: Offset(centerX, centerY), radius: radius));

    final tailPath = Path()
      ..moveTo(centerX - radius * 0.35, centerY + radius * 0.7)
      ..lineTo(centerX, h)
      ..lineTo(centerX + radius * 0.35, centerY + radius * 0.7)
      ..close();

    final fullPath = Path.combine(PathOperation.union, path, tailPath);

    canvas.drawShadow(fullPath, Colors.black.withOpacity(0.4), 4.0, true);

    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(fullPath, whitePaint);

    final borderPaint = Paint()
      ..color = _getPinColor(type)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(fullPath, borderPaint);
  }

  Color _getPinColor(WazePinType t) {
    switch (t) {
      case WazePinType.police:
        return const Color(0xFF0284C7);
      case WazePinType.radar:
        return const Color(0xFF0EA5E9);
      case WazePinType.hazard:
        return const Color(0xFFF59E0B);
      case WazePinType.traffic:
        return const Color(0xFFEF4444);
      case WazePinType.accident:
        return const Color(0xFFDC2626);
      case WazePinType.mood:
        return const Color(0xFFF43F5E);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
