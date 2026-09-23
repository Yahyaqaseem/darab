import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/darb_icons.dart';
import '../../shared_widgets/darb_card.dart';
import '../../shared_widgets/darb_button.dart';
import 'update_fuel_sheet.dart';
import '../navigation/navigation_screen.dart';

class FuelScreen extends StatefulWidget {
  const FuelScreen({super.key});

  @override
  State<FuelScreen> createState() => _FuelScreenState();
}

class _FuelScreenState extends State<FuelScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.fuelStations.isEmpty) {
        appState.loadNearbyData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final stations = appState.fuelStations;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('محطات الوقود والأسعار', style: DarbTypography.title),
        actions: [
          IconButton(
            icon: const DarbIcon(DarbIconType.refresh, size: 24, color: DarbColors.primaryEmerald),
            onPressed: () => appState.loadNearbyData(),
          ),
        ],
      ),
      body: stations.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DarbIcon(DarbIconType.fuel, size: 54, color: DarbColors.primaryEmerald),
                  const SizedBox(height: DarbSpacing.md),
                  Text('جاري جلب المحطات القريبة...', style: DarbTypography.body.copyWith(color: DarbColors.textSecondary)),
                  const SizedBox(height: DarbSpacing.lg),
                  DarbButton(
                    text: 'تحديث المحطات',
                    icon: DarbIconType.refresh,
                    isFullWidth: false,
                    onPressed: () => appState.loadNearbyData(),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: DarbSpacing.lg, vertical: DarbSpacing.md),
              itemCount: stations.length,
              itemBuilder: (ctx, idx) {
                final s = stations[idx];
                final updatedAgoMins = DateTime.now().difference(s.priceUpdatedAt).inMinutes;

                return Padding(
                  padding: const EdgeInsets.only(bottom: DarbSpacing.md),
                  child: DarbCard(
                    padding: const EdgeInsets.all(DarbSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(DarbSpacing.sm),
                              decoration: BoxDecoration(
                                color: DarbColors.primaryEmerald.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const DarbIcon(DarbIconType.fuel, color: DarbColors.primaryEmerald, size: 26),
                            ),
                            const SizedBox(width: DarbSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          s.nameAr,
                                          style: DarbTypography.section,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (s.isVerified) ...[
                                        const SizedBox(width: DarbSpacing.xs),
                                        const DarbIcon(DarbIconType.verified, color: DarbColors.primaryEmerald, size: 18),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    s.address,
                                    style: DarbTypography.caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (s.distanceKm != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: DarbSpacing.sm, vertical: DarbSpacing.xs),
                                decoration: BoxDecoration(
                                  color: DarbColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: DarbColors.border.withOpacity(0.3)),
                                ),
                                child: Text(
                                  ' كم',
                                  style: DarbTypography.label.copyWith(color: DarbColors.textPrimary),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: DarbSpacing.lg),

                        // Fuel Prices Row
                        Row(
                          children: [
                            Expanded(child: _buildPricePill('عادي', '', DarbColors.primaryEmerald)),
                            const SizedBox(width: DarbSpacing.sm),
                            Expanded(child: _buildPricePill('محسن', '', DarbColors.warningOrange)),
                            const SizedBox(width: DarbSpacing.sm),
                            Expanded(child: _buildPricePill('ديزل', '', DarbColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: DarbSpacing.md),

                        // Availability & Crowd Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: s.isPetrolAvailable ? DarbColors.successGreen : DarbColors.dangerRed,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: DarbSpacing.xs),
                                Text(
                                  s.isPetrolAvailable ? 'متوفر' : 'غير متوفر',
                                  style: DarbTypography.label.copyWith(
                                    color: s.isPetrolAvailable ? DarbColors.successGreen : DarbColors.dangerRed,
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: DarbSpacing.sm),
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: DarbColors.textDisabled,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Text(
                                  s.crowdText,
                                  style: DarbTypography.label.copyWith(color: s.crowdColor),
                                ),
                              ],
                            ),
                            Text(
                              updatedAgoMins > 0 ? 'قبل  دقيقة' : 'الآن',
                              style: DarbTypography.caption,
                            ),
                          ],
                        ),
                        const SizedBox(height: DarbSpacing.lg),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: DarbButton(
                                text: 'ابدأ الملاحة',
                                icon: DarbIconType.route,
                                size: DarbButtonSize.small,
                                isFullWidth: true,
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => NavigationScreen(
                                    destinationName: s.nameAr,
                                    destLat: s.latitude,
                                    destLng: s.longitude,
                                  )));
                                },
                              ),
                            ),
                            const SizedBox(width: DarbSpacing.sm),
                            Expanded(
                              flex: 1,
                              child: DarbButton(
                                text: 'تحديث',
                                variant: DarbButtonVariant.secondary,
                                size: DarbButtonSize.small,
                                isFullWidth: true,
                                onPressed: () => UpdateFuelSheet.show(context, s),
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

  Widget _buildPricePill(String title, String price, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: DarbSpacing.sm),
      decoration: BoxDecoration(
        color: DarbColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DarbColors.border.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(title, style: DarbTypography.caption),
          const SizedBox(height: 2),
          Text(
            price,
            style: DarbTypography.numeric.copyWith(color: color, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
