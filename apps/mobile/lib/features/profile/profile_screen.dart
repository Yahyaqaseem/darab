import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/darb_icons.dart';
import '../../shared_widgets/darb_card.dart';
import '../../shared_widgets/darb_switch.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('حسابي والسمعة', style: DarbTypography.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: DarbSpacing.lg, vertical: DarbSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Driver Profile Card
            DarbCard(
              padding: const EdgeInsets.all(DarbSpacing.xxl),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: DarbColors.primaryEmerald.withOpacity(0.15),
                    child: const DarbIcon(DarbIconType.profile, size: 48, color: DarbColors.primaryEmerald),
                  ),
                  const SizedBox(height: DarbSpacing.md),
                  Text(
                    appState.driverUsername,
                    style: DarbTypography.title,
                  ),
                  const SizedBox(height: DarbSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: DarbSpacing.md, vertical: DarbSpacing.xs),
                    decoration: BoxDecoration(
                      color: DarbColors.textSecondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const DarbIcon(DarbIconType.verified, color: DarbColors.textSecondary, size: 16),
                        const SizedBox(width: DarbSpacing.xs),
                        Text(
                          'مستخدم جديد',
                          style: DarbTypography.caption.copyWith(color: DarbColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DarbSpacing.xl),

                  // Points and Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('نقاط السمعة', '', DarbColors.primaryEmerald),
                      _buildStatColumn('البلاغات المؤكدة', '0', DarbColors.warningOrange),
                      _buildStatColumn('إجابات مفيدة', '0', DarbColors.infoBlue),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: DarbSpacing.xl),

            // Badges Section
            Text('الأوسمة المكتسبة', style: DarbTypography.section),
            const SizedBox(height: DarbSpacing.md),
            Center(child: Text('لا توجد أوسمة بعد', style: DarbTypography.caption)),
            const SizedBox(height: DarbSpacing.xxl),

            // Settings & Preferences
            Text('الإعدادات والخصوصية', style: DarbTypography.section),
            const SizedBox(height: DarbSpacing.md),
            DarbCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: DarbSpacing.lg, vertical: DarbSpacing.xs),
                    leading: const DarbIcon(DarbIconType.info, color: DarbColors.textPrimary), // Placeholder for globe/language
                    title: Text('لغة التطبيق', style: DarbTypography.body),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          appState.currentLanguage == 'ar' ? 'العربية' :
                          (appState.currentLanguage == 'ku' ? 'کوردی' : 'English'),
                          style: DarbTypography.body.copyWith(color: DarbColors.primaryEmerald),
                        ),
                        const SizedBox(width: DarbSpacing.sm),
                        const DarbIcon(DarbIconType.chevronLeft, size: 14, color: DarbColors.textSecondary),
                      ],
                    ),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => Container(
                          decoration: const BoxDecoration(
                            color: DarbColors.surface,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          child: SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(DarbSpacing.lg),
                                  child: Text('اختر اللغة', style: DarbTypography.title),
                                ),
                                _buildLanguageOption(context, 'العربية', 'ar', appState),
                                const Divider(height: 1, color: DarbColors.border),
                                _buildLanguageOption(context, 'کوردی (Kurdish)', 'ku', appState),
                                const Divider(height: 1, color: DarbColors.border),
                                _buildLanguageOption(context, 'English', 'en', appState),
                                const SizedBox(height: DarbSpacing.lg),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, color: DarbColors.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DarbSpacing.lg),
                    child: DarbSwitch(
                      label: 'التوجيه الصوتي أثناء القيادة',
                      subtitle: 'سيتم تنبيهك صوتياً بالمنعطفات',
                      value: true,
                      onChanged: (_) {},
                    ),
                  ),
                  const Divider(height: 1, color: DarbColors.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DarbSpacing.lg),
                    child: DarbSwitch(
                      label: 'الوضع الليلي (Dark Mode)',
                      value: appState.isDarkMode,
                      onChanged: (_) => appState.toggleTheme(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: DarbTypography.numeric.copyWith(fontSize: 24, color: color),
        ),
        const SizedBox(height: 4),
        Text(label, style: DarbTypography.caption),
      ],
    );
  }

  Widget _buildLanguageOption(BuildContext context, String label, String code, AppState appState) {
    final isSelected = appState.currentLanguage == code;
    return ListTile(
      title: Text(label, textAlign: TextAlign.center, style: DarbTypography.section.copyWith(
        color: isSelected ? DarbColors.primaryEmerald : DarbColors.textPrimary,
      )),
      trailing: isSelected ? const DarbIcon(DarbIconType.verified, color: DarbColors.primaryEmerald) : null,
      onTap: () {
        appState.setLanguage(code);
        Navigator.pop(context);
      },
    );
  }
}
