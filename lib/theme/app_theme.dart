import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary - Indigo Blue
  static const Color primary = Color(0xFF3B5CCC);
  static const Color primaryLight = Color(0xFFE8EDFA);
  static const Color primaryForeground = Color(0xFFFAFAFF);

  // Accent - Teal Green
  static const Color accent = Color(0xFF2BB87E);
  static const Color accentLight = Color(0xFFE6F8F0);
  static const Color accentForeground = Color(0xFF141B2E);

  // Neutrals (light)
  static const Color background = Color(0xFFF5F6FA);
  static const Color foreground = Color(0xFF141B2E);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardForeground = Color(0xFF141B2E);
  static const Color border = Color(0xFFE2E5F0);
  static const Color muted = Color(0xFFECEEF5);
  static const Color mutedForeground = Color(0xFF717894);
  static const Color secondary = Color(0xFFEEF0F7);
  static const Color secondaryForeground = Color(0xFF2A3150);

  // Semantic
  static const Color destructive = Color(0xFFDC4A4A);
  static const Color chartOrange = Color(0xFFC87A30);
  static const Color chartBlue = Color(0xFF4E8BC7);

  // Dark mode neutrals
  static const Color darkBackground = Color(0xFF0F1117);
  static const Color darkForeground = Color(0xFFE8EAF0);
  static const Color darkCard = Color(0xFF1A1D27);
  static const Color darkCardForeground = Color(0xFFE8EAF0);
  static const Color darkBorder = Color(0xFF2A2D3A);
  static const Color darkMuted = Color(0xFF232632);
  static const Color darkMutedForeground = Color(0xFF8B8FA8);
  static const Color darkSecondary = Color(0xFF1E2130);
  static const Color darkSecondaryForeground = Color(0xFFCBCFE0);
  static const Color darkPrimaryLight = Color(0xFF1E2747);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.primaryForeground,
        secondary: AppColors.secondary,
        onSecondary: AppColors.secondaryForeground,
        surface: AppColors.card,
        onSurface: AppColors.foreground,
        error: AppColors.destructive,
        outline: AppColors.border,
      ),
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.secondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.primaryForeground,
        secondary: AppColors.darkSecondary,
        onSecondary: AppColors.darkSecondaryForeground,
        surface: AppColors.darkCard,
        onSurface: AppColors.darkForeground,
        error: AppColors.destructive,
        outline: AppColors.darkBorder,
      ),
      textTheme: _buildTextTheme(Brightness.dark),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static SystemUiOverlayStyle overlayStyleFor(ThemeMode mode, BuildContext ctx) {
    final isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(ctx) == Brightness.dark);
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor:
          isDark ? AppColors.darkCard : Colors.white,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final color = brightness == Brightness.light
        ? AppColors.foreground
        : AppColors.darkForeground;

    final mutedColor = brightness == Brightness.light
        ? AppColors.mutedForeground
        : AppColors.darkMutedForeground;

    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.dmSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      displayMedium: GoogleFonts.dmSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      titleLarge: GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: mutedColor,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: mutedColor,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dynamic color accessor — returns light or dark color based on current theme.
// Usage:  context.colors.background  /  context.colors.card  / etc.
// ---------------------------------------------------------------------------

class DynamicColors {
  const DynamicColors._(this.isDark);
  final bool isDark;

  // Adaptive
  Color get background => isDark ? AppColors.darkBackground : AppColors.background;
  Color get foreground => isDark ? AppColors.darkForeground : AppColors.foreground;
  Color get card => isDark ? AppColors.darkCard : AppColors.card;
  Color get cardForeground => isDark ? AppColors.darkCardForeground : AppColors.cardForeground;
  Color get border => isDark ? AppColors.darkBorder : AppColors.border;
  Color get muted => isDark ? AppColors.darkMuted : AppColors.muted;
  Color get mutedForeground => isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
  Color get secondary => isDark ? AppColors.darkSecondary : AppColors.secondary;
  Color get secondaryForeground => isDark ? AppColors.darkSecondaryForeground : AppColors.secondaryForeground;
  Color get primaryLight => isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight;

  // Fixed (same in both modes)
  Color get primary => AppColors.primary;
  Color get primaryForeground => AppColors.primaryForeground;
  Color get accent => AppColors.accent;
  Color get accentLight => AppColors.accentLight;
  Color get accentForeground => AppColors.accentForeground;
  Color get destructive => AppColors.destructive;
  Color get chartOrange => AppColors.chartOrange;
  Color get chartBlue => AppColors.chartBlue;
}

extension AppColorsContext on BuildContext {
  DynamicColors get colors {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return DynamicColors._(isDark);
  }
}
