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

  Future<void> _sendQuestion(String type) async {
    setState(() => _isSending = true);
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.askRoadQuestion(type);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.radar_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'تم إرسال نداء الطريق للسائقين الموجودين أمامك على نفس المسار!',
                style: TextStyle( fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: AppTheme.primaryEmerald,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  DarbIconType _getQuestionIcon(String type) {
    switch (type) {
      case 'TRAFFIC':
        return DarbIconType.traffic;
      case 'ROAD_CONDITION':
        return DarbIconType.badRoad;
      case 'ACCIDENT':
        return DarbIconType.accident;
      case 'CHECKPOINT':
        return DarbIconType.checkpoint;
      case 'FUEL_AVAILABILITY':
        return DarbIconType.fuel;
      default:
        return DarbIconType.roadCall;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
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
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const DarbIcon(DarbIconType.roadCall, color: AppTheme.accentOrange, size: 26),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نداء الطريق (سؤال السائقين أمامك)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'يُرسل فقط للسائقين الموجودين أمامك على نفس الطريق',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Question Templates List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: AppConstants.roadCallTemplates.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, idx) {
                final item = AppConstants.roadCallTemplates[idx];

                return Material(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: _isSending ? null : () => _sendQuestion(item['type']),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          DarbIcon(_getQuestionIcon(item['type'] as String), color: AppTheme.primaryEmerald, size: 24),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              item['title'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}
