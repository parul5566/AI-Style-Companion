import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized app theme — dark, modern, fashion-forward aesthetic.
class AppTheme {
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryDark = Color(0xFF5849C7);
  static const Color accent = Color(0xFFE84393);
  static const Color background = Color(0xFF0F0E17);
  static const Color surface = Color(0xFF1A1923);
  static const Color surfaceLight = Color(0xFF252437);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9B9AAD);
  static const Color divider = Color(0xFF2D2C3F);
  static const Color success = Color(0xFF00CEC9);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color error = Color(0xFFFF7675);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
        error: error,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        const TextTheme(
          headlineLarge: TextStyle(color: textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
          bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
          bodySmall: TextStyle(color: textSecondary, fontSize: 12),
          labelLarge: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: textSecondary.withOpacity(0.6)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: false,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLight,
        labelStyle: GoogleFonts.poppins(color: textPrimary, fontSize: 13),
        selectedColor: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
