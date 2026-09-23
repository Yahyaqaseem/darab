import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class DarbSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double huge = 32.0;
}

class DarbColors {
  // Brand
  static const Color primaryEmerald = Color(0xFF10B981);
  static const Color primaryEmeraldLight = Color(0xFF34D399);
  static const Color primaryEmeraldDark = Color(0xFF059669);

  // Backgrounds & Surfaces (Dark Premium Base)
  static const Color background = Color(0xFF0F172A);
  static const Color surface = Color(0xFF1E293B);
  static const Color card = Color(0xFF334155);

  // Typography Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFF475569);
  
  // Inverse Typography
  static const Color textInversePrimary = Color(0xFF0F172A);

  // Status & Alerts
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);
  static const Color infoBlue = Color(0xFF3B82F6);

  // Utility
  static const Color border = Color(0xFF475569);
  static const Color divider = Color(0xFF1E293B);
  static const Color overlay = Color(0x800F172A);
}

class DarbTypography {
  static final TextStyle _baseCairo = GoogleFonts.cairo();

  static TextStyle get display => _baseCairo.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: DarbColors.textPrimary,
  );

  static TextStyle get title => _baseCairo.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: DarbColors.textPrimary,
  );

  static TextStyle get section => _baseCairo.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: DarbColors.textPrimary,
  );

  static TextStyle get body => _baseCairo.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: DarbColors.textPrimary,
  );

  static TextStyle get caption => _baseCairo.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: DarbColors.textSecondary,
  );

  static TextStyle get numeric => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: DarbColors.textPrimary,
  );
}

class AppTheme {
  // Maintaining for backward compatibility until full refactor is done
  static const Color primaryEmerald = DarbColors.primaryEmerald;
  static const Color accentOrange = DarbColors.warningOrange;
  static const Color darkBackground = DarbColors.background;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: DarbColors.primaryEmerald,
      scaffoldBackgroundColor: DarbColors.background,
      fontFamily: GoogleFonts.cairo().fontFamily,
      
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: DarbColors.textPrimary),
        titleTextStyle: DarbTypography.title,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      colorScheme: const ColorScheme.dark(
        primary: DarbColors.primaryEmerald,
        secondary: DarbColors.warningOrange,
        surface: DarbColors.surface,
        background: DarbColors.background,
        error: DarbColors.dangerRed,
      ),
      textTheme: TextTheme(
        displayLarge: DarbTypography.display,
        titleLarge: DarbTypography.title,
        titleMedium: DarbTypography.section,
        bodyLarge: DarbTypography.body,
        bodyMedium: DarbTypography.body,
        bodySmall: DarbTypography.caption,
      ),
    );
  }
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: DarbColors.primaryEmerald,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      fontFamily: GoogleFonts.cairo().fontFamily,
      
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: DarbColors.textInversePrimary),
        titleTextStyle: DarbTypography.title.copyWith(color: DarbColors.textInversePrimary),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      colorScheme: const ColorScheme.light(
        primary: DarbColors.primaryEmerald,
        secondary: DarbColors.warningOrange,
        surface: Colors.white,
        background: Color(0xFFF8FAFC),
        error: DarbColors.dangerRed,
      ),
      textTheme: TextTheme(
        displayLarge: DarbTypography.display.copyWith(color: DarbColors.textInversePrimary),
        titleLarge: DarbTypography.title.copyWith(color: DarbColors.textInversePrimary),
        titleMedium: DarbTypography.section.copyWith(color: DarbColors.textInversePrimary),
        bodyLarge: DarbTypography.body.copyWith(color: DarbColors.textInversePrimary),
        bodyMedium: DarbTypography.body.copyWith(color: DarbColors.textInversePrimary),
        bodySmall: DarbTypography.caption.copyWith(color: const Color(0xFF64748B)),
      ),
    );
  }
}
