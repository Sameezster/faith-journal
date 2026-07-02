import '../../../../core/constants/app_assets.dart';

/// One onboarding page's content.
class OnboardingPageData {
  const OnboardingPageData({
    required this.image,
    required this.title,
    required this.subtitle,
  });

  final String image;
  final String title;
  final String subtitle;
}

/// The three onboarding pages, in order.
const List<OnboardingPageData> onboardingPages = [
  OnboardingPageData(
    image: AppAssets.onboardingBible,
    title: 'Read the Bible',
    subtitle: 'Read the Word in KJV, NIV and Tamil.',
  ),
  OnboardingPageData(
    image: AppAssets.onboardingReflect,
    title: 'Save & Reflect',
    subtitle: 'Save meaningful verses and write your reflections.',
  ),
  OnboardingPageData(
    image: AppAssets.onboardingPrayer,
    title: 'Track Your Prayers',
    subtitle: 'Follow each prayer from request to answered.',
  ),
];
