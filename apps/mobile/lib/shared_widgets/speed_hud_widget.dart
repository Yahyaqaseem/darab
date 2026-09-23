import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class SpeedHudWidget extends StatelessWidget {
  final double currentSpeedKmh;
  final double speedLimit;

  const SpeedHudWidget({
    super.key,
    required this.currentSpeedKmh,
    this.speedLimit = 120.0,
  });

  @override
  Widget build(BuildContext context) {
    final isOverSpeed = currentSpeedKmh > speedLimit;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isOverSpeed ? DarbColors.dangerRed : DarbColors.background.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverSpeed ? Colors.white : Colors.white24,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${currentSpeedKmh.round()}',
            style: DarbTypography.numeric.copyWith(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          Text(
            'كم / ساعة',
            style: DarbTypography.caption.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

