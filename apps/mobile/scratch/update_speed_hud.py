import re

file_path = r'C:\Users\Yahya\Downloads\darab\apps\mobile\lib\shared_widgets\speed_hud_widget.dart'

new_code = """import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class SpeedHudWidget extends StatelessWidget {
  final double currentSpeedKmh;
  final double speedLimit;

  const SpeedHudWidget({
    super.key,
    required this.currentSpeedKmh,
    this.speedLimit = 80.0, // Default to 80 to demonstrate UI
  });

  @override
  Widget build(BuildContext context) {
    final isOverSpeed = currentSpeedKmh > speedLimit;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF07101F).withOpacity(0.7) : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isOverSpeed 
                  ? DarbColors.dangerRed.withOpacity(0.8) 
                  : (isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.05)),
              width: isOverSpeed ? 2 : 1,
            ),
            boxShadow: [
              if (isOverSpeed)
                BoxShadow(
                  color: DarbColors.dangerRed.withOpacity(0.3),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Speed Limit Sign (Classic Traffic Sign Style)
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: DarbColors.dangerRed, width: 4.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '${speedLimit.round()}',
                  style: DarbTypography.numeric.copyWith(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Divider
              Container(
                width: 1.5,
                height: 36,
                color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
              ),
              
              const SizedBox(width: 16),
              
              // Current Speed
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${currentSpeedKmh.round()}',
                    style: DarbTypography.numeric.copyWith(
                      color: isOverSpeed ? DarbColors.dangerRed : (isDark ? Colors.white : Colors.black87),
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    'كم / س',
                    style: DarbTypography.caption.copyWith(
                      color: isOverSpeed ? DarbColors.dangerRed.withOpacity(0.8) : (isDark ? Colors.white70 : DarbColors.textSecondary),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}
"""

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(new_code)

print("Speed HUD Widget updated successfully!")
