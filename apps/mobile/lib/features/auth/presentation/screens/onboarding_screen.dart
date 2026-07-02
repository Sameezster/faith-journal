import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/sparkle_divider.dart';
import 'onboarding_content.dart';

/// Onboarding flow — three swipeable pages introducing the app.
///
/// Layout matches the approved mockups: a top illustration, a Playfair title,
/// the gold–sparkle–gold divider, a subtitle, page dots, and a Skip link with
/// a gold Next button (which becomes "Get Started" on the last page).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  bool get _isLastPage => _page == onboardingPages.length - 1;

  void _onNext() {
    if (_isLastPage) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finish() {
    context.go('/welcome');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Swipeable pages.
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: onboardingPages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _OnboardingPage(data: onboardingPages[i]),
              ),
            ),

            // Page dots.
            _Dots(count: onboardingPages.length, current: _page),
            const SizedBox(height: 28),

            // Skip + Next / Get Started.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _finish,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.warmGray,
                      textStyle: AppTextStyles.body,
                    ),
                    child: const Text('Skip'),
                  ),
                  ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(150, 54),
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                    ),
                    child: Text(_isLastPage ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single onboarding page: illustration, title, divider, subtitle.
class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),

          // Illustration.
          Image.asset(data.image, fit: BoxFit.contain),

          const Spacer(flex: 1),

          // Title.
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.appTitle.copyWith(fontSize: 32),
          ),
          const SizedBox(height: 14),

          // Divider.
          const SparkleDivider(lineWidth: 40, sparkleSize: 14),
          const SizedBox(height: 16),

          // Subtitle.
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.warmGray),
          ),

          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

/// Animated row of page-indicator dots.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: active ? 11 : 9,
          height: active ? 11 : 9,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: active ? AppColors.gold : AppColors.sage.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
