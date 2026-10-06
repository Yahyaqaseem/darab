import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/darb_icons.dart';
import '../../shared_widgets/darb_card.dart';
import '../../shared_widgets/darb_button.dart';

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
    final durationFormatted = hours > 0 ? ' س  د' : ' دقيقة';
    final avgSpeed = (widget.distanceKm / (widget.durationSeconds / 3600)).clamp(20.0, 140.0);

    return Scaffold(
      backgroundColor: DarbColors.background,
      appBar: AppBar(
        title: Text('ملخص الرحلة', style: DarbTypography.title),
        leading: IconButton(
          icon: const DarbIcon(DarbIconType.close, size: 24, color: DarbColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DarbSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success Header
            Center(
              child: Container(
                padding: const EdgeInsets.all(DarbSpacing.lg),
                decoration: BoxDecoration(
                  color: DarbColors.primaryEmerald.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const DarbIcon(DarbIconType.route, color: DarbColors.primaryEmerald, size: 48),
              ),
            ),
            const SizedBox(height: DarbSpacing.sm),
            Text(
              'الحمد لله على سلامتك!',
              textAlign: TextAlign.center,
              style: DarbTypography.display,
            ),
            Text(
              'وصلت إلى  بنجاح',
              textAlign: TextAlign.center,
              style: DarbTypography.body.copyWith(color: DarbColors.textSecondary),
            ),
            const SizedBox(height: DarbSpacing.xl),

            // Route Path Card
            DarbCard(
              padding: const EdgeInsets.all(DarbSpacing.lg),
              child: Row(
                children: [
                  Column(
                    children: [
                      const DarbIcon(DarbIconType.route, color: DarbColors.primaryEmerald, size: 14),
                      const SizedBox(height: 4),
                      Container(width: 2, height: 24, color: DarbColors.border),
                      const SizedBox(height: 4),
                      const DarbIcon(DarbIconType.route, color: DarbColors.dangerRed, size: 18),
                    ],
                  ),
                  const SizedBox(width: DarbSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.startName, style: DarbTypography.section),
                        const SizedBox(height: DarbSpacing.lg),
                        Text(widget.endName, style: DarbTypography.section),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DarbSpacing.md),

            // Stats Grid
            Row(
              children: [
                _buildStatTile('المسافة الكلية', ' كم', DarbIconType.route, isDark),
                const SizedBox(width: DarbSpacing.sm),
                _buildStatTile('مدة الرحلة', durationFormatted, DarbIconType.refresh, isDark), // Re-using refresh temporarily for timer
              ],
            ),
            const SizedBox(height: DarbSpacing.sm),
            Row(
              children: [
                _buildStatTile('السرعة المتوسطة', ' كم/س', DarbIconType.radar, isDark),
                const SizedBox(width: DarbSpacing.sm),
                _buildStatTile('السرعة الموثوقة', ' كم/س', DarbIconType.verified, isDark),
              ],
            ),
            const SizedBox(height: DarbSpacing.lg),

            // Anomaly Filter Notice
            if (hasAnomaly) ...[
              Container(
                padding: const EdgeInsets.all(DarbSpacing.md),
                decoration: BoxDecoration(
                  color: DarbColors.primaryEmerald.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: DarbColors.primaryEmerald.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const DarbIcon(DarbIconType.verified, color: DarbColors.primaryEmerald, size: 26),
                    const SizedBox(width: DarbSpacing.sm),
                    Expanded(
                      child: Text(
                        'تم تصفية طفرة الـ GPS العشوائية ( كم/س) واحتساب السرعة الموثوقة ( كم/س) بنظام الذكاء الاصطناعي.',
                        style: DarbTypography.caption.copyWith(color: DarbColors.primaryEmerald, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DarbSpacing.lg),
            ],

            // Trip Replay Preview Box
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: DarbColors.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DarbIcon(DarbIconType.route, size: 48, color: DarbColors.primaryEmerald.withOpacity(0.8)),
                      const SizedBox(height: DarbSpacing.sm),
                      Text(
                        _isReplaying ? 'جارِ تشغيل الإعادة: %' : 'مشاهدة إعادة مسار الرحلة',
                        style: DarbTypography.body.copyWith(fontWeight: FontWeight.bold),
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
                        color: DarbColors.primaryEmerald,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: DarbSpacing.xxl),

            Row(
              children: [
                Expanded(
                  child: DarbButton(
                    text: 'إعادة المسار',
                    icon: DarbIconType.refresh,
                    variant: DarbButtonVariant.secondary,
                    size: DarbButtonSize.large,
                    isFullWidth: true,
                    onPressed: _isReplaying ? null : _triggerReplay,
                  ),
                ),
                const SizedBox(width: DarbSpacing.sm),
                Expanded(
                  child: DarbButton(
                    text: 'تم والعودة',
                    size: DarbButtonSize.large,
                    isFullWidth: true,
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

  Widget _buildStatTile(String label, String value, DarbIconType icon, bool isDark) {
    return Expanded(
      child: DarbCard(
        padding: const EdgeInsets.all(DarbSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DarbIcon(icon, color: DarbColors.primaryEmerald, size: 22),
            const SizedBox(height: DarbSpacing.sm),
            Text(label, style: DarbTypography.caption),
            const SizedBox(height: 2),
            Text(value, style: DarbTypography.numeric),
          ],
        ),
      ),
    );
  }
}
