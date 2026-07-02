import 'package:flutter/material.dart';

/// Central color palette for Faith Journal.
///
/// Keep every hardcoded color out of widgets — reference these instead so the
/// whole app stays consistent and a future re-skin is a one-file change.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Brand / surfaces
  // ---------------------------------------------------------------------------
  /// Warm ivory — the default app background.
  static const Color ivory = Color(0xFFF7F3EC);

  /// Deep midnight navy — headings, primary dark surfaces.
  static const Color navy = Color(0xFF1C2540);

  /// Warm divine gold — primary accent, buttons, active states.
  static const Color gold = Color(0xFFC8A24A);

  /// Soft sage green — secondary accent, status chips.
  static const Color sage = Color(0xFF9FB3A0);

  /// Champagne highlight — verse-of-the-day cards, selected verse background.
  static const Color champagne = Color(0xFFEFE3C8);

  /// Pure white — cards and input fields sitting on the ivory background.
  static const Color white = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------------
  /// Main body text.
  static const Color charcoal = Color(0xFF222222);

  /// Secondary text, captions, dates, field labels.
  static const Color warmGray = Color(0xFF6B6B6B);

  /// Placeholder / disabled text.
  static const Color placeholder = Color(0xFFA8A29A);

  // ---------------------------------------------------------------------------
  // Status / feedback
  // ---------------------------------------------------------------------------
  /// Errors.
  static const Color error = Color(0xFFC0584B);

  /// Success — e.g. an "Answered" prayer.
  static const Color success = Color(0xFF5B8A5A);

  // ---------------------------------------------------------------------------
  // Convenience aliases (semantic names used across the UI)
  // ---------------------------------------------------------------------------
  static const Color background = ivory;
  static const Color surface = white;
  static const Color primary = gold;
  static const Color onPrimary = white;
  static const Color secondary = sage;
  static const Color textPrimary = charcoal;
  static const Color textSecondary = warmGray;
  static const Color heading = navy;
  static const Color link = gold;

  /// Hairline dividers / subtle borders.
  static const Color divider = Color(0xFFE6DFD2);
}
