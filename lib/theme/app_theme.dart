import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF4CAF50);
  static const primaryLight = Color(0xFF81C784);
  static const primaryPale = Color(0xFFE8F5E9);

  static const secondary = Color(0xFF81C784);
  static const secondaryLight = Color(0xFFA5D6A7);
  static const secondaryPale = Color(0xFFF1F8E9);

  static const accent = Color(0xFFFFC107);
  static const accentPale = Color(0xFFFFF8E1);

  static const cream = Color(0xFFF8F9FA);
  static const warm = Color(0xFFF1F3F5);
  static const warmBorder = Color(0xFFDEE2E6);

  static const dark = Color(0xFF212529);
  static const darkMid = Color(0xFF495057);
  static const muted = Color(0xFF868E96);

  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFEF4444);
}

/// Category accent colors
const Map<String, Color> categoryColors = {
  'all': Color(0xFF4CAF50),
  'dog': Color(0xFFFFC107),
  'cat': Color(0xFF2BAE9F),
  'rabbit': Color(0xFF8B5CF6),
  'bird': Color(0xFFEC4899),
  'other': Color(0xFF6366F1),
};

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.cream,
        error: AppColors.error,
        brightness: Brightness.light,
      ),
    );

    final displayFont = GoogleFonts.interTextTheme();
    final bodyFont = GoogleFonts.outfitTextTheme();

    return base.copyWith(
      textTheme: bodyFont.copyWith(
        titleLarge: displayFont.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.dark,
        ),
        titleMedium: displayFont.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.dark,
        ),
        bodyMedium: bodyFont.bodyMedium?.copyWith(color: AppColors.darkMid),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.dark,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.warmBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4,
        shadowColor: AppColors.dark.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.dark,
        error: AppColors.error,
        brightness: Brightness.dark,
      ),
    );

    final displayFont = GoogleFonts.interTextTheme();
    final bodyFont = GoogleFonts.outfitTextTheme();

    return base.copyWith(
      textTheme: bodyFont.copyWith(
        titleLarge: displayFont.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
        titleMedium: displayFont.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        bodyMedium: bodyFont.bodyMedium?.copyWith(color: Colors.white70),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.dark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkMid,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.darkMid, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: const TextStyle(color: Colors.white60),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkMid,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

/// Font style shortcut for headings, mirroring `font-family: 'Inter'`.
TextStyle nunito({
  double size = 14,
  FontWeight weight = FontWeight.w700,
  Color color = AppColors.dark,
}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

/// Body font shortcut, mirroring `font-family: 'Outfit'`.
TextStyle outfit({
  double size = 14,
  FontWeight weight = FontWeight.w400,
  Color color = AppColors.darkMid,
  double? height,
}) =>
    GoogleFonts.outfit(fontSize: size, fontWeight: weight, color: color, height: height);
