import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color brandPrimary = Color(0xFF1FC8A5);
  static const Color brandSecondary = Color(0xFF27DFAF);

  static ThemeData get dark {
    final baseTextTheme = GoogleFonts.rajdhaniTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.rajdhani().fontFamily,
      textTheme: baseTextTheme,
      colorScheme: const ColorScheme.dark(
        primary: brandPrimary,
        secondary: brandSecondary,
        surface: Color(0xFF11161E),
      ),
      scaffoldBackgroundColor: const Color(0xFF0B1017),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0B1017),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF151D28),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandPrimary,
          foregroundColor: const Color(0xFF06231F),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: Color(0xFF151D28),
        selectedColor: brandPrimary,
        side: BorderSide.none,
        labelStyle: TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF121A24),
        margin: EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      ),
    );
  }
}
