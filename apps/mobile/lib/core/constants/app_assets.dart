/// Central registry of asset paths for Faith Journal.
///
/// Reference these instead of typing raw strings — one typo-proof place to
/// update if a file is ever renamed or moved.
class AppAssets {
  AppAssets._();

  static const String _bg = 'assets/bg_img';
  static const String _icons = 'assets/icons_img';
  static const String _onboarding = 'assets/onboarding';
  static const String _home = 'assets/home_img';

  /// Glowing light-ray / clouds background used on Splash & welcome screens.
  static const String backgroundLight = '$_bg/bg-img-1.png';

  /// Soft glow + leaves background used on the auth/form screens.
  static const String backgroundSoft = '$_bg/bg-img-2.png';

  /// Main app logo — cross above an open Bible.
  static const String logo = '$_icons/icon-1.png';

  /// Brand logos for the social sign-in buttons.
  static const String googleLogo = '$_icons/google.png';
  static const String appleLogo = '$_icons/apple.png';

  // Onboarding illustrations.
  static const String onboardingBible = '$_onboarding/onboarding-1.png';
  static const String onboardingReflect = '$_onboarding/onboarding-2.png';
  static const String onboardingPrayer = '$_onboarding/onboarding-3.png';

  // Home dashboard imagery.
  static const String homeVerse = '$_home/home-img-1.png';
  static const String homeReflection1 = '$_home/home-img-2.png';
  static const String homeReflection2 = '$_home/home-img-3.png';
  static const String profileAvatar = '$_home/profile-img.png';

  // Quick-action icons (colored line style).
  static const String actionBible = '$_icons/bible.png';
  static const String actionJournal = '$_icons/journal.png';
  static const String actionPrayer = '$_icons/prayer.png';
  static const String actionSearch = '$_icons/search.png';

  /// Monochrome praying-hands icon for the Prayer nav tab.
  static const String navPray = '$_icons/pray.png';
}
