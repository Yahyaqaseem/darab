import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Primary Palette
  static const Color primaryEmerald = Color(0xFF10B981);
  static const Color primaryEmeraldLight = Color(0xFF34D399);
  static const Color primaryEmeraldDark = Color(0xFF059669);

  // Secondary Palette
  static const Color secondarySand = Color(0xFFFDE68A);
  static const Color secondarySandLight = Color(0xFFFEF3C7);
  static const Color secondarySandDark = Color(0xFFB45309);

  // Accents & Alerts
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color alertRed = Color(0xFFEF4444);
  static const Color alertAmber = Color(0xFFF59E0B);
  static const Color successGreen = Color(0xFF10B981);
  static const Color infoBlue = Color(0xFF3B82F6);

  // Backgrounds & Surfaces
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkCharcoal = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkSurface = Color(0xFF334155);

  static const Color lightBackground = Color(0xFFF8FAFC);
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
      brightness: Brightness.light,
      primaryColor: primaryEmerald,
      scaffoldBackgroundColor: lightBackground,
       // Assuming Cairo is loaded in pubspec
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: darkBackground),
        titleTextStyle: TextStyle(color: darkBackground, fontSize: 18, fontWeight: FontWeight.bold),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      colorScheme: ColorScheme.light(
        primary: primaryEmerald,
        secondary: accentOrange,
        surface: lightCard,
        background: lightBackground,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryEmerald,
      scaffoldBackgroundColor: darkBackground,
      
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      colorScheme: ColorScheme.dark(
        primary: primaryEmerald,
        secondary: accentOrange,
        surface: darkCard,
        background: darkBackground,
      ),
    );
  }
}
