import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Premium Modern Colors
  static const Color primaryEmerald = Color(0xFF10b981);
  static const Color primaryEmeraldDark = Color(0xFF059669);
  static const Color accentOrange = Color(0xFFf59e0b);
  static const Color alertRed = Color(0xFFef4444);
  static const Color infoBlue = Color(0xFF3b82f6);

  // Backgrounds & Surfaces
  static const Color darkBackground = Color(0xFF0f172a);
  static const Color darkCard = Color(0xFF1e293b);
  static const Color lightBackground = Color(0xFFf8fafc);
  static const Color lightCard = Color(0xFFffffff);

  static const Color secondarySand = Color(0xFFfde68a);
  static const Color secondarySandDark = Color(0xFFb45309);
  
  static const Color successGreen = Color(0xFF10b981);

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
