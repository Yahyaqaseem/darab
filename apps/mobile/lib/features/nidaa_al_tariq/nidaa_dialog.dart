import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/darb_icons.dart';

class NidaaDialog extends StatefulWidget {
  const NidaaDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const NidaaDialog(),
    );
  }

  @override
  State<NidaaDialog> createState() => _NidaaDialogState();
}

class _NidaaDialogState extends State<NidaaDialog> {
  bool _isSending = false;
  bool _isSent = false;
  String _sentType = '';

  Future<void> _sendQuestion(String type) async {
    setState(() => _isSending = true);
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.askRoadQuestion(type);

    if (mounted) {
      setState(() {
        _isSending = false;
        _isSent = true;
        _sentType = type;
      });
      
      // Close after short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
    }
  }

  // Use simple icons matching the user prompt examples
  Widget _buildQuestionButton(String text, String type, bool isDark) {
    return Material(
      color: isDark ? DarbColors.surface : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _isSending ? null : () => _sendQuestion(type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: DarbTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : DarbColors.textInversePrimary,
                  ),
                ),
              ),
              if (_isSending)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.arrow_forward_ios, size: 14, color: DarbColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 32),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            if (_isSent)
              // Sent confirmation state (Animated)
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Transform.scale(
                          scale: value,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: DarbColors.successGreen.withOpacity(0.15),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: DarbColors.successGreen.withOpacity(0.3 * value),
                                  blurRadius: 20 * value,
                                  spreadRadius: 2 * value,
                                )
                              ],
                            ),
                            child: const Icon(Icons.check, color: DarbColors.successGreen, size: 48),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Opacity(
                          opacity: value.clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, 10 * (1 - value)),
                            child: Column(
                              children: [
                                Text(
                                  '✓ تم إرسال نداء الطريق',
                                  style: DarbTypography.title.copyWith(color: DarbColors.successGreen, fontSize: 22),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'بانتظار إجابات السائقين...',
                                  style: DarbTypography.body.copyWith(color: DarbColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
            else
              // Question selection state
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const DarbIcon(DarbIconType.roadCall, color: DarbColors.primaryYellow, size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'نداء الطريق',
                            style: DarbTypography.title.copyWith(
                              fontSize: 20,
                              color: isDark ? Colors.white : DarbColors.textInversePrimary,
                            ),
                          ),
                          Text(
                            'السائقين على هذا الطريق الآن', // We omit the number as backend lacks matching API to avoid faking
                            style: DarbTypography.caption.copyWith(
                              color: DarbColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Question Grid / List
                  _buildQuestionButton('🚗 هل يوجد زحام؟', 'TRAFFIC', isDark),
                  const SizedBox(height: 8),
                  _buildQuestionButton('🚧 هل يوجد إغلاق بالطريق؟', 'CLOSURE', isDark),
                  const SizedBox(height: 8),
                  _buildQuestionButton('⚠️ هل يوجد حادث؟', 'ACCIDENT', isDark),
                  const SizedBox(height: 8),
                  _buildQuestionButton('👮 هل يوجد سيطرة / نقطة تفتيش؟', 'CHECKPOINT', isDark),
                  const SizedBox(height: 8),
                  _buildQuestionButton('💧 هل يوجد تجمع مياه؟', 'FLOOD', isDark),
                  const SizedBox(height: 8),
                  _buildQuestionButton('⛽ هل توجد مشكلة بمحطات الوقود؟', 'FUEL_ISSUE', isDark),
                  const SizedBox(height: 8),
                  _buildQuestionButton('🔧 هل توجد سيارة متعطلة؟', 'BROKEN_CAR', isDark),
                  const SizedBox(height: 8),
                  _buildQuestionButton('🛣️ كيف وضع الطريق؟', 'ROAD_CONDITION', isDark),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
