import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_theme.dart';
import 'nidaa_dialog.dart';

class NidaaFeedSheet extends StatelessWidget {
  const NidaaFeedSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final questions = appState.activeRoadQuestions;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('نداءات الطريق النشطة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => appState.loadNearbyData(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accentOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.radar_rounded),
        label: const Text(
          'أطلق نداء طريق',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
        ),
        onPressed: () => NidaaDialog.show(context),
      ),
      body: questions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.radar_outlined, size: 64, color: AppTheme.accentOrange.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد نداءات طريق حالية على مسارك',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'إذا كنت في حيرة من وضع الطريق، اطلب معلومات من السائقين أمامك',
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
              itemCount: questions.length,
              itemBuilder: (ctx, idx) {
                final q = questions[idx];

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: AppTheme.accentOrange.withOpacity(0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.accentOrange.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.radar_rounded, color: AppTheme.accentOrange, size: 22),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    q.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                  Text(
                                    q.roadName,
                                    style: TextStyle(
                                      color: isDark ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
                                      fontSize: 12,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.accentOrange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${q.totalAnswers} إجابة',
                                style: const TextStyle(
                                  color: AppTheme.accentOrange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (q.aggregatedSummary != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.alertRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.alertRed.withOpacity(0.3)),
                            ),
                            child: Text(
                              q.aggregatedSummary!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.alertRed,
                                fontSize: 13,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),
                        const Text(
                          'أجب لمساعدة السائق خلفك (+2 نقطة سمعة):',
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Cairo'),
                        ),
                        const SizedBox(height: 8),

                        // Fast Voting Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryEmerald,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 42),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => appState.answerRoadQuestion(q.id, 'نعم'),
                                child: Text('نعم (${q.answersYes})', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                                  foregroundColor: isDark ? Colors.white : AppTheme.textDarkPrimary,
                                  elevation: 0,
                                  minimumSize: const Size(0, 42),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => appState.answerRoadQuestion(q.id, 'لا'),
                                child: Text('لا (${q.answersNo})', style: const TextStyle(fontFamily: 'Cairo')),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 42),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => appState.answerRoadQuestion(q.id, 'غير متأكد'),
                                child: const Text('غير متأكد', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
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
