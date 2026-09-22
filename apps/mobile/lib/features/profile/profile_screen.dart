import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../shared_widgets/driver_safe_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي والسمعة', style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          IconButton(
            icon: Icon(appState.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: () => appState.toggleTheme(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Driver Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primaryEmerald.withOpacity(0.15),
                    child: const Icon(Icons.person_pin_rounded, size: 52, color: AppTheme.primaryEmerald),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    appState.driverUsername,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.secondarySand.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_rounded, color: AppTheme.secondarySandDark, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'مستخدم جديد',
                          style: TextStyle(
                            color: AppTheme.secondarySandDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Points and Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('نقاط السمعة', '', AppTheme.primaryEmerald),
                      _buildStatColumn('البلاغات المؤكدة', '0', AppTheme.accentOrange),
                      _buildStatColumn('إجابات مفيدة', '0', Colors.blue),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Badges Section
            const Text(
              'الأوسمة المكتسبة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 10),
            const Center(child: Text('لا توجد أوسمة بعد', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey))),
            const SizedBox(height: 24),

            // Garage (Vehicles) Section
            const Text(
              'مرآب سياراتي',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 10),
            const Center(child: Text('لا توجد مركبات مضافة', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey))),
            const SizedBox(height: 24),

            // Settings & Preferences
            const Text(
              'الإعدادات والخصوصية',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language_rounded),
                    title: const Text('لغة التطبيق', style: TextStyle(fontFamily: 'Cairo')),
                    trailing: const Text('العربية', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.volume_up_rounded),
                    title: const Text('التوجيه الصوتي أثناء القيادة', style: TextStyle(fontFamily: 'Cairo')),
                    trailing: Switch(value: true, activeColor: AppTheme.primaryEmerald, onChanged: (_) {}),
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
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color, fontFamily: 'Cairo')),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Cairo')),
      ],
    );
  }
}
