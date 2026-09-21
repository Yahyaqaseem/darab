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
        title: const Text('حسابي والسمعة'),
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
                          'المستوى: خبير طرق (Road Expert)',
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
                      _buildStatColumn('نقاط السمعة', '${appState.reputationScore}', AppTheme.primaryEmerald),
                      _buildStatColumn('البلاغات المؤكدة', '38', AppTheme.accentOrange),
                      _buildStatColumn('إجابات مفيدة', '24', Colors.blue),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Badges Section
            const Text(
              'الأوسمة المكتسبة (Badges)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildBadgeCard('عين أربيل', Icons.visibility_rounded, isDark),
                const SizedBox(width: 10),
                _buildBadgeCard('خبير الطرق', Icons.verified_rounded, isDark),
                const SizedBox(width: 10),
                _buildBadgeCard('ملك السفر', Icons.navigation_rounded, isDark),
              ],
            ),
            const SizedBox(height: 24),

            // Garage (Vehicles) Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'مرآب سياراتي (Garage)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('إضافة سيارة', style: TextStyle(fontFamily: 'Cairo')),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryEmerald.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.directions_car_rounded, color: AppTheme.primaryEmerald, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Toyota Land Cruiser 2023', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo')),
                        Text('السيارة الأساسية الحالية', style: TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo')),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle, color: AppTheme.primaryEmerald, size: 22),
                ],
              ),
            ),
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
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('حماية الموقع وهوية السائق المجهولة', style: TextStyle(fontFamily: 'Cairo')),
                    trailing: const Icon(Icons.check, color: AppTheme.successGreen),
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

  Widget _buildBadgeCard(String title, IconData icon, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.secondarySand.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.secondarySandDark, size: 28),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
            ),
          ],
        ),
      ),
    );
  }
}
