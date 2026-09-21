import 'package:flutter/material.dart';

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
        color: isOverSpeed ? const Color(0xFFEF4444) : const Color(0xFF0F172A).withOpacity(0.85),
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
              height: 1.0,
            ),
          ),
          const Text(
            'كم / ساعة',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}
