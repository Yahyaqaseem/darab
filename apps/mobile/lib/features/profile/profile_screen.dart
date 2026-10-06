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
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text(
          lang == 'en' ? 'My Profile' : (lang == 'ku' ? 'هەژماری من' : 'حسابي'),
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: DarbIcon(DarbIconType.settings, color: textColor),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Header / Editorial Profile
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: DarbColors.primaryYellow.withOpacity(0.2),
                  child: const Text('YK', style: TextStyle(color: DarbColors.primaryYellow, fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Text('Yahya Qaseem', style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Top Driver • 4,500 pts', style: TextStyle(color: DarbColors.primaryYellow, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Stats Group
          Text(lang == 'en' ? 'STATISTICS' : 'الإحصائيات', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: surfaceColor,
              child: Column(
                children: [
                  _buildListTile(DarbIconType.history, 'Reports Submitted', '12', textColor, isDark),
                  _buildDivider(isDark),
                  _buildListTile(DarbIconType.verified, 'Helpful Answers', '45', textColor, isDark),
                  _buildDivider(isDark),
                  _buildListTile(DarbIconType.route, 'Distance Driven', '1,200 km', textColor, isDark),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Settings Group
          Text(lang == 'en' ? 'PREFERENCES' : 'التفضيلات', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: surfaceColor,
              child: Column(
                children: [
                  _buildListTile(DarbIconType.home, lang == 'en' ? 'Home Address' : 'عنوان المنزل', null, textColor, isDark),
                  _buildDivider(isDark),
                  _buildListTile(DarbIconType.work, lang == 'en' ? 'Work Address' : 'عنوان العمل', null, textColor, isDark),
                  _buildDivider(isDark),
                  _buildThemeToggle(context, appState, textColor, isDark),
                  _buildDivider(isDark),
                  _buildListTile(DarbIconType.trafficFlow, lang == 'en' ? 'Navigation Settings' : 'إعدادات الملاحة', null, textColor, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(DarbIconType icon, String title, String? value, Color textColor, bool isDark) {
    return ListTile(
      leading: DarbIcon(icon, color: DarbColors.primaryYellow, size: 22),
      title: Text(title, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: value != null 
          ? Text(value, style: const TextStyle(color: Color(0xFF64748B), fontSize: 15))
          : const Icon(Icons.chevron_right, color: Color(0xFF64748B), size: 20),
    );
  }

  Widget _buildThemeToggle(BuildContext context, AppState appState, Color textColor, bool isDark) {
    return ListTile(
      leading: const Icon(Icons.dark_mode_rounded, color: DarbColors.primaryYellow, size: 22),
      title: Text('الوضع الليلي', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500)),
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
