import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import 'update_fuel_sheet.dart';

class FuelScreen extends StatelessWidget {
  const FuelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final stations = appState.fuelStations;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('محطات الوقود والأسعار'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => appState.loadNearbyData(),
          ),
        ],
      ),
      body: stations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: stations.length,
              itemBuilder: (ctx, idx) {
                final s = stations[idx];
                final updatedAgoMins = DateTime.now().difference(s.priceUpdatedAt).inMinutes;

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryEmerald.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.local_gas_station_rounded, color: AppTheme.primaryEmerald, size: 26),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          s.nameAr,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (s.isVerified) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.verified_rounded, color: AppTheme.primaryEmerald, size: 18),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    s.address,
                                    style: TextStyle(
                                      color: isDark ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
                                      fontSize: 12,
                                      fontFamily: 'Cairo',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (s.distanceKm != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondarySand.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${s.distanceKm!.toStringAsFixed(1)} كم',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Fuel Prices Grid
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildPriceTag('بنزين عادي', '${s.petrolPrice} د.ع', AppTheme.primaryEmerald),
                              _buildPriceTag('بنزين محسن', '${s.premiumPrice} د.ع', AppTheme.accentOrange),
                              _buildPriceTag('ديزل / كاز', '${s.dieselPrice} د.ع', Colors.blueGrey),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Availability & Crowd Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: s.isPetrolAvailable ? AppTheme.successGreen : AppTheme.alertRed,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  s.isPetrolAvailable ? 'الوقود متوفر' : 'غير متوفر حالياً',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: s.isPetrolAvailable ? AppTheme.successGreen : AppTheme.alertRed,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'الازدحام: ${s.crowdText}',
                                  style: TextStyle(fontSize: 12, color: s.crowdColor, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                                ),
                              ],
                            ),
                            Text(
                              updatedAgoMins > 0 ? 'قبل $updatedAgoMins دقيقة' : 'الآن',
                              style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryEmerald,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 42),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.navigation_rounded, size: 18),
                                label: const Text('المسار إلى المحطة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  appState.startNavigation({
                                    'name': s.nameAr,
                                    'distanceKm': s.distanceKm ?? 2.5,
                                    'durationMinutes': 6,
                                  }, s.nameAr, s.latitude, s.longitude);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 42),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.edit_note_rounded, size: 18),
                              label: const Text('تحديث السعر', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                              onPressed: () => UpdateFuelSheet.show(context, s),
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

  Widget _buildPriceTag(String title, String price, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo')),
        const SizedBox(height: 2),
        Text(
          price,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color, fontFamily: 'Cairo'),
        ),
      ],
    );
  }
}
