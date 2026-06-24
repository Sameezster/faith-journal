import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Builds the app ThemeData from design tokens.
/// Display/headings use a serif (Playfair Display); UI/body uses a sans (Inter).
class AppTheme {
  static ThemeData light() {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    final serif = GoogleFonts.playfairDisplayTextTheme(base.textTheme);
    final sans = GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: FjColors.cream50,
      colorScheme: const ColorScheme.light(
        primary: FjColors.gold500,
        onPrimary: Colors.white,
        secondary: FjColors.navy900,
        surface: FjColors.surface0,
        onSurface: FjColors.navy900,
      ),
      textTheme: sans.copyWith(
        displayLarge: serif.displayLarge?.copyWith(
          fontWeight: FontWeight.bold, color: FjColors.navy900),
        headlineMedium: serif.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold, color: FjColors.navy900),
        titleLarge: serif.titleLarge?.copyWith(
          fontWeight: FontWeight.w600, color: FjColors.navy900),
        bodyMedium: sans.bodyMedium?.copyWith(color: FjColors.navy700),
        bodySmall: sans.bodySmall?.copyWith(color: FjColors.gray500),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FjColors.gold500,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FjRadius.button)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      cardTheme: CardThemeData(
        color: FjColors.surface0,
        elevation: 2,
        shadowColor: FjColors.navy900.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FjRadius.card)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FjColors.surface0,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FjRadius.input),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
