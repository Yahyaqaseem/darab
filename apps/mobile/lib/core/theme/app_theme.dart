import 'package:flutter/material.dart';

class AppTheme {
  // Primary Palette (Emerald Green)
  static const Color primaryEmerald = Color(0xFF0A5C36);
  static const Color primaryEmeraldLight = Color(0xFF10B981);
  static const Color primaryEmeraldDark = Color(0xFF063B23);

  // Secondary Palette (Sand / Beige)
  static const Color secondarySand = Color(0xFFD4B996);
  static const Color secondarySandLight = Color(0xFFF3EDE2);
  static const Color secondarySandDark = Color(0xFFA68B68);

  // Accents & Alerts
  static const Color accentOrange = Color(0xFFF97316);
  static const Color alertRed = Color(0xFFEF4444);
  static const Color alertAmber = Color(0xFFF59E0B);
  static const Color successGreen = Color(0xFF22C55E);

  // Dark & Light Base Colors
  static const Color darkCharcoal = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkSurface = Color(0xFF334155);

  static const Color lightOffWhite = Color(0xFFF8FAFC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF1F5F9);

  // Text Colors
  static const Color textDarkPrimary = Color(0xFF0F172A);
  static const Color textDarkSecondary = Color(0xFF64748B);
  static const Color textLightPrimary = Color(0xFFF8FAFC);
  static const Color textLightSecondary = Color(0xFF94A3B8);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryEmerald,
      scaffoldBackgroundColor: lightOffWhite,
      colorScheme: const ColorScheme.light(
        primary: primaryEmerald,
        secondary: secondarySand,
        surface: lightCard,
        error: alertRed,
        onPrimary: Colors.white,
        onSecondary: darkCharcoal,
        onSurface: textDarkPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightCard,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textDarkPrimary),
        titleTextStyle: TextStyle(
          color: textDarkPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
      ),
      cardTheme: CardTheme(
        color: lightCard,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryEmerald,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: textDarkPrimary),
        headlineMedium: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: textDarkPrimary),
        titleLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: textDarkPrimary),
        bodyLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w500, color: textDarkPrimary),
        bodyMedium: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.normal, color: textDarkSecondary),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryEmeraldLight,
      scaffoldBackgroundColor: darkCharcoal,
      colorScheme: const ColorScheme.dark(
        primary: primaryEmeraldLight,
        secondary: secondarySand,
        surface: darkCard,
        error: alertRed,
        onPrimary: darkCharcoal,
        onSecondary: Colors.white,
        onSurface: textLightPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkCard,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textLightPrimary),
        titleTextStyle: TextStyle(
          color: textLightPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
      ),
      cardTheme: CardTheme(
        color: darkCard,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryEmeraldLight,
          foregroundColor: darkCharcoal,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: textLightPrimary),
        headlineMedium: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: textLightPrimary),
        titleLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: textLightPrimary),
        bodyLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w500, color: textLightPrimary),
        bodyMedium: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.normal, color: textLightSecondary),
      ),
    );
  }
}
