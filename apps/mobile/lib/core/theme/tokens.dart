import 'package:flutter/material.dart';

/// Design tokens extracted from the Faith Journal design file (single source of truth).
/// Palette: deep navy (headings), goldenrod (primary action), cream (canvas), white (cards),
/// sage (positive secondary), neutral grays.
abstract class FjColors {
  static const navy900 = Color(0xFF16314E); // display headings, active nav
  static const navy700 =
      Color(0xFF1F3D5C); // secondary headings, icons on cream
  static const gold500 =
      Color(0xFFC8962F); // primary buttons, active chips/tabs, FAB
  static const gold300 = Color(0xFFE4C77D); // pressed/hover, subtle accents
  static const cream50 =
      Color(0xFFF4F0E6); // app background / onboarding canvas
  static const surface0 = Color(0xFFFFFFFF); // cards, sheets, inputs
  static const sage500 = Color(0xFF8A9A7B); // success / positive secondary text
  static const gray500 = Color(0xFF8C8C8C); // body / secondary text
  static const gray300 = Color(0xFFD9D6CC); // dividers, inactive chips
  static const statusActive = gold500;
  static const statusWaiting = Color(0xFFB98A2E);
  static const statusAnswered = Color(0xFF5E7D5A);
}

abstract class FjSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const gutter = 20.0;
}

abstract class FjRadius {
  static const input = 12.0;
  static const chip = 12.0;
  static const card = 16.0;
  static const cardLg = 20.0;
  static const button = 16.0;
}
