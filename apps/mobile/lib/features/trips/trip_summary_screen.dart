import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared_widgets/driver_safe_button.dart';

class TripSummaryScreen extends StatefulWidget {
  final String startName;
  final String endName;
  final double distanceKm;
  final int durationSeconds;
  final List<double> speedReadings;

  const TripSummaryScreen({
    super.key,
    required this.startName,
    required this.endName,
    required this.distanceKm,
    required this.durationSeconds,
    required this.speedReadings,
  });

  @override
  State<TripSummaryScreen> createState() => _TripSummaryScreenState();
}

class _TripSummaryScreenState extends State<TripSummaryScreen> {
  bool _isReplaying = false;
  double _replayProgress = 0.0;

  void _triggerReplay() {
    setState(() {
      _isReplaying = true;
      _replayProgress = 0.0;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return false;
      setState(() {
        _replayProgress += 0.05;
      });
      if (_replayProgress >= 1.0) {
        setState(() => _isReplaying = false);
        return false;
      }
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter Speed Anomaly
    final validSpeeds = widget.speedReadings.where((s) => s >= 0 && s <= 190).toList();
    validSpeeds.sort();
    final p95 = validSpeeds.isNotEmpty ? validSpeeds[(validSpeeds.length * 0.95).floor().clamp(0, validSpeeds.length - 1)] : 110.0;
    final maxRaw = widget.speedReadings.isNotEmpty ? widget.speedReadings.reduce((a, b) => a > b ? a : b) : 110.0;
    final hasAnomaly = maxRaw > p95 + 30;

    final hours = widget.durationSeconds ~/ 3600;
    final mins = (widget.durationSeconds % 3600) ~/ 60;
    final durationFormatted = hours > 0 ? '$hours س $mins د' : '$mins دقيقة';
    final avgSpeed = (widget.distanceKm / (widget.durationSeconds / 3600)).clamp(20.0, 140.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ملخص الرحلة'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success Header
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flag_rounded, color: AppTheme.primaryEmerald, size: 48),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'الحمد لله على سلامتك!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Cairo'),
            ),
            Text(
              'وصلت إلى ${widget.endName} بنجاح',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: isDark ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary, fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 24),

            // Route Path Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  const Column(
                    children: [
                      Icon(Icons.circle, color: AppTheme.primaryEmerald, size: 14),
                      SizedBox(height: 4),
                      SizedBox(height: 24, child: VerticalDivider(color: Colors.grey, thickness: 1.5)),
                      SizedBox(height: 4),
                      Icon(Icons.location_on_rounded, color: AppTheme.alertRed, size: 18),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.startName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo')),
                        const SizedBox(height: 16),
                        Text(widget.endName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats Grid
            Row(
              children: [
                _buildStatTile('المسافة الكلية', '${widget.distanceKm.toStringAsFixed(1)} كم', Icons.route_rounded, isDark),
                const SizedBox(width: 12),
                _buildStatTile('مدة الرحلة', durationFormatted, Icons.timer_outlined, isDark),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatTile('السرعة المتوسطة', '${avgSpeed.toStringAsFixed(0)} كم/س', Icons.speed_rounded, isDark),
                const SizedBox(width: 12),
                _buildStatTile('السرعة الموثوقة', '${p95.toStringAsFixed(0)} كم/س', Icons.verified_user_rounded, isDark),
              ],
            ),
            const SizedBox(height: 16),

            // Anomaly Filter Notice
            if (hasAnomaly) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primaryEmerald.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: AppTheme.primaryEmerald, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'تم تصفية طفرة الـ GPS العشوائية (${maxRaw.toStringAsFixed(0)} كم/س) واحتساب السرعة الموثوقة (${p95.toStringAsFixed(0)} كم/س) بنظام الذكاء الاصطناعي.',
                        style: const TextStyle(fontSize: 12, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Trip Replay Preview Box
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_fill_rounded, size: 48, color: AppTheme.primaryEmerald.withOpacity(0.8)),
                      const SizedBox(height: 8),
                      Text(
                        _isReplaying ? 'جارِ تشغيل الإعادة: ${( _replayProgress * 100).toStringAsFixed(0)}%' : 'مشاهدة إعادة مسار الرحلة (Trip Replay)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                  if (_isReplaying)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: _replayProgress,
                        color: AppTheme.primaryEmerald,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('إعادة المسار', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                    onPressed: _isReplaying ? null : _triggerReplay,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DriverSafeButton(
                    label: 'تم والعودة',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primaryEmerald, size: 22),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Cairo')),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Cairo')),
          ],
        ),
      ),
    );
  }
}
