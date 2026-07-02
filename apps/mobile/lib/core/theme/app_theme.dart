import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Assembles the Faith Journal [ThemeData].
///
/// Use `AppTheme.light` as the app's `theme`. Individual widgets should still
/// reach for [AppColors] / [AppTextStyles] directly when they need a specific
/// brand token, but most Material defaults are pre-styled here.
class AppTheme {
  AppTheme._();

  /// Shared radius for cards, buttons and inputs (~18px per the design spec).
  static const double radius = 18.0;
  static final BorderRadius borderRadius = BorderRadius.circular(radius);

  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.gold,
      onPrimary: AppColors.white,
      secondary: AppColors.sage,
      onSecondary: AppColors.navy,
      surface: AppColors.white,
      onSurface: AppColors.charcoal,
      error: AppColors.error,
      onError: AppColors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.ivory,
      splashColor: AppColors.gold.withValues(alpha: 0.12),
      highlightColor: AppColors.gold.withValues(alpha: 0.08),
      dividerColor: AppColors.divider,

      // -----------------------------------------------------------------------
      // Text
      // -----------------------------------------------------------------------
      textTheme: TextTheme(
        displayLarge: AppTextStyles.appTitle,
        headlineLarge: AppTextStyles.h1,
        headlineMedium: AppTextStyles.h2,
        titleLarge: AppTextStyles.verseReference,
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.body,
        labelLarge: AppTextStyles.label,
        bodySmall: AppTextStyles.caption,
      ),

      // -----------------------------------------------------------------------
      // App bar
      // -----------------------------------------------------------------------
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.ivory,
        foregroundColor: AppColors.navy,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.h2,
        iconTheme: const IconThemeData(color: AppColors.navy),
      ),

      // -----------------------------------------------------------------------
      // Cards
      // -----------------------------------------------------------------------
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 1.5,
        shadowColor: AppColors.navy.withValues(alpha: 0.08),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
      ),

      // -----------------------------------------------------------------------
      // Buttons
      // -----------------------------------------------------------------------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.gold.withValues(alpha: 0.5),
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold,
          textStyle: AppTextStyles.link,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          backgroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: AppColors.divider),
          textStyle: AppTextStyles.chip,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
      ),

      // -----------------------------------------------------------------------
      // Inputs
      // -----------------------------------------------------------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.placeholder),
        labelStyle: AppTextStyles.label,
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),

      // -----------------------------------------------------------------------
      // Chips (tags / filters)
      // -----------------------------------------------------------------------
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.champagne.withValues(alpha: 0.5),
        selectedColor: AppColors.gold,
        labelStyle: AppTextStyles.chip,
        secondaryLabelStyle: AppTextStyles.chipActive,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),

      // -----------------------------------------------------------------------
      // Bottom navigation
      // -----------------------------------------------------------------------
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.warmGray,
        selectedLabelStyle: AppTextStyles.navLabelActive,
        unselectedLabelStyle: AppTextStyles.navLabel,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showUnselectedLabels: true,
      ),

      // -----------------------------------------------------------------------
      // Floating action button (e.g. "+" on Prayers)
      // -----------------------------------------------------------------------
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.white,
        elevation: 2,
      ),

      // -----------------------------------------------------------------------
      // Bottom sheets (verse-action sheet)
      // -----------------------------------------------------------------------
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        modalBackgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.white
              : AppColors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.gold
              : AppColors.placeholder,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
