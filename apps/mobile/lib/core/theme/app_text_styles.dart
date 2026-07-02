import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography system for Faith Journal.
///
/// Three families (all free Google Fonts):
///  • Playfair Display → headings, titles, verse references (elegant serif)
///  • Inter            → body, buttons, labels, nav (clean sans-serif)
///  • Lora             → Bible scripture reading only (comfortable long-read serif)
///
/// Sizes match the agreed type scale 1:1. Use these everywhere instead of
/// building TextStyles inline.
class AppTextStyles {
  AppTextStyles._();

  // ---------------------------------------------------------------------------
  // Display / titles — Playfair Display
  // ---------------------------------------------------------------------------

  /// App title on Splash / Welcome. 32 · Medium (elegant, not heavy).
  static TextStyle get appTitle => GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w500,
        height: 1.2,
        letterSpacing: 0.5,
        color: AppColors.navy,
      );

  /// Screen title (H1). 24 · Bold.
  static TextStyle get h1 => GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.navy,
      );

  /// Section heading (H2). 20 · SemiBold.
  static TextStyle get h2 => GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AppColors.navy,
      );

  /// Verse reference (e.g. "Isaiah 41:10"). 18 · Medium.
  static TextStyle get verseReference => GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: AppColors.navy,
      );

  // ---------------------------------------------------------------------------
  // Scripture reader — Lora
  // ---------------------------------------------------------------------------

  /// Scripture text in the Bible reader. 18 · Regular · roomy line height.
  static TextStyle get scripture => GoogleFonts.lora(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: AppColors.charcoal,
      );

  /// Superscript verse number inside the reader.
  static TextStyle get verseNumber => GoogleFonts.lora(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.0,
        color: AppColors.gold,
      );

  // ---------------------------------------------------------------------------
  // Body & UI — Inter
  // ---------------------------------------------------------------------------

  /// Body / paragraph. 16 · Regular.
  static TextStyle get body => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.charcoal,
      );

  /// Primary button text. 16 · SemiBold · white (sits on gold).
  static TextStyle get button => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AppColors.white,
      );

  /// Input / field label. 14 · Medium · warm gray.
  static TextStyle get label => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.warmGray,
      );

  /// Chip / tab / filter (inactive). 14 · Medium · navy.
  static TextStyle get chip => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.navy,
      );

  /// Chip / tab / filter (active). 14 · Medium · gold.
  static TextStyle get chipActive => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.gold,
      );

  /// Caption / date / helper. 12 · Regular · warm gray.
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.warmGray,
      );

  /// Bottom nav label. 11 · Medium · gray.
  static TextStyle get navLabel => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: AppColors.warmGray,
      );

  /// Bottom nav label (active). 11 · Medium · gold.
  static TextStyle get navLabelActive => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AppColors.gold,
      );

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Link / inline accent text built on the body style.
  static TextStyle get link => body.copyWith(
        color: AppColors.gold,
        fontWeight: FontWeight.w600,
      );

  /// Error helper text.
  static TextStyle get errorText => caption.copyWith(color: AppColors.error);
}
