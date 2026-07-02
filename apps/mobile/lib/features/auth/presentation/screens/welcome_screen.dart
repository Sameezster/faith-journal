import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/sparkle_divider.dart';

/// Welcome screen — shown after onboarding.
///
/// Full-screen light-ray background with the logo seated in the glow, the
/// "Welcome to Faith Journal" wordmark, the sparkle divider, a tagline, a
/// full-width gold "Get Started" button and a "Sign In" link.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _onGetStarted(BuildContext context) {
    context.push('/register');
  }

  void _onSignIn(BuildContext context) {
    context.push('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background (glow + clouds + leaves).
          Image.asset(AppAssets.backgroundLight, fit: BoxFit.cover),

          // Foreground content.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 24),

                  // Logo, seated in the glow.
                  Image.asset(
                    AppAssets.logo,
                    width: 170,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 28),

                  // Headline.
                  Text(
                    'Welcome to\nFaith Journal',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.appTitle.copyWith(
                      fontSize: 40,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Divider.
                  const SparkleDivider(lineWidth: 44, sparkleSize: 15),
                  const SizedBox(height: 18),

                  // Tagline.
                  Text(
                    'Your personal spiritual memory companion',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.warmGray,
                    ),
                  ),

                  const Spacer(flex: 16),

                  // Primary action.
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () => _onGetStarted(context),
                      child: const Text('Get Started'),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Secondary action.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.warmGray),
                      ),
                      GestureDetector(
                        onTap: () => _onSignIn(context),
                        child: Text(
                          'Sign In',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(flex: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
