import '../search/destination_search_screen.dart';
import 'location_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/darb_icons.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = appState.currentLanguage;
    final bgColor = isDark ? DarbColors.background : const Color(0xFFF8FAFC);
    final surfaceColor = isDark ? DarbColors.surface : Colors.white;
    final textColor = isDark ? DarbColors.textPrimary : DarbColors.textInversePrimary;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang == 'en' ? 'My Profile' : (lang == 'ku' ? 'هەژماری من' : 'حسابي'),
                  style: DarbTypography.title.copyWith(color: textColor),
                ),
                IconButton(
                  icon: DarbIcon(DarbIconType.settings, color: textColor),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // Header / Editorial Profile
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: DarbColors.primaryYellow.withOpacity(0.15),
                        child: Text(
                          appState.driverUsername.substring(0, min(2, appState.driverUsername.length)).toUpperCase(), 
                          style: DarbTypography.display.copyWith(color: DarbColors.primaryYellow)
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(appState.driverUsername, style: DarbTypography.title.copyWith(color: textColor)),
                      const SizedBox(height: 4),
                      Text(
                        '${appState.trustLevel} • ${appState.reputationScore} pts',
                        style: DarbTypography.body.copyWith(color: DarbColors.primaryYellow, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                
                // Stats Group
                Text(
                  lang == 'en' ? 'STATISTICS' : 'الإحصائيات',
                  style: DarbTypography.caption.copyWith(color: DarbColors.textSecondary, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: surfaceColor,
                    child: Column(
                      children: [
                        _buildListTile(context, DarbIconType.history, 'البلاغات المرسلة', '12', textColor, isDark),
                        _buildDivider(isDark),
                        _buildListTile(context, DarbIconType.verified, 'الإجابات الموثوقة', '45', textColor, isDark),
                        _buildDivider(isDark),
                        _buildListTile(context, DarbIconType.route, 'المسافة المقطوعة', '1,200 km', textColor, isDark),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Settings Group
                Text(
                  lang == 'en' ? 'PREFERENCES' : 'التفضيلات',
                  style: DarbTypography.caption.copyWith(color: DarbColors.textSecondary, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: surfaceColor,
                    child: Column(
                      children: [
                        _buildListTile(context, DarbIconType.home, lang == 'en' ? 'Home Address' : 'عنوان المنزل', null, textColor, isDark, onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => LocationPickerScreen(title: lang == 'en' ? 'Set Home' : 'تحديد المنزل')));
                        }),
                        _buildDivider(isDark),
                        _buildListTile(context, DarbIconType.work, lang == 'en' ? 'Work Address' : 'عنوان العمل', null, textColor, isDark, onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => LocationPickerScreen(title: lang == 'en' ? 'Set Work' : 'تحديد العمل')));
                        }),
                        _buildDivider(isDark),
                        _buildThemeToggle(context, appState, textColor, isDark),
                        _buildDivider(isDark),
                        _buildListTile(context, DarbIconType.trafficFlow, lang == 'en' ? 'Navigation Settings' : 'إعدادات الملاحة', null, textColor, isDark),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(BuildContext context, DarbIconType icon, String title, String? value, Color textColor, bool isDark, {VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('سيتم تفعيل هذه الخاصية في التحديث القادم!', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: DarbColors.primaryYellow,
            behavior: SnackBarBehavior.floating,
          )
        );
      },
      leading: DarbIcon(icon, color: DarbColors.textSecondary, size: 22),
      title: Text(title, style: DarbTypography.body.copyWith(color: textColor, fontWeight: FontWeight.w600)),
      trailing: value != null 
          ? Text(value, style: DarbTypography.body.copyWith(color: DarbColors.textSecondary, fontWeight: FontWeight.w600))
          : const Icon(Icons.chevron_right, color: DarbColors.textSecondary, size: 20),
    );
  }

  Widget _buildThemeToggle(BuildContext context, AppState appState, Color textColor, bool isDark) {
    return ListTile(
      onTap: () {
        appState.toggleTheme();
      },
      leading: const Icon(Icons.dark_mode_rounded, color: DarbColors.textSecondary, size: 22),
      title: Text('الوضع الليلي', style: DarbTypography.body.copyWith(color: textColor, fontWeight: FontWeight.w600)),
      trailing: Switch.adaptive(
        value: appState.isDarkMode,
        activeColor: DarbColors.primaryYellow,
        onChanged: (val) => appState.toggleTheme(),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 54),
      color: isDark ? Colors.white12 : Colors.black12,
    );
  }
}
// added min to fix substring error
int min(int a, int b) => a < b ? a : b;
