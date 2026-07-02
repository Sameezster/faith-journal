import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/sparkle_divider.dart';
import '../providers/auth_providers.dart';

/// Splash screen — first thing the user sees.
///
/// Layout matches the approved design: full-screen light-ray background, the
/// cross-and-book logo, the "Faith Journal" wordmark, a gold–sparkle–gold
/// divider, the tagline, and three loading dots near the bottom.
///
/// After a short pause it routes:
///   - authenticated user -> /home
///   - first-time / signed-out user -> /onboarding
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2500), _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    final user = ref.read(authStateProvider).value;
    context.go(user == null ? '/onboarding' : '/home');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image (glowing light + clouds).
          Image.asset(
            AppAssets.backgroundLight,
            fit: BoxFit.cover,
          ),

          // Foreground content — logo block lifted up so it sits inside the
          // glow, dots pinned near the bottom.
          SafeArea(
            child: Stack(
              children: [
                // Logo + wordmark, aligned into the upper-glow region.
                Align(
                  alignment: const Alignment(0, -0.30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        AppAssets.logo,
                        width: 160,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Faith Journal',
                        style: AppTextStyles.appTitle.copyWith(fontSize: 40),
                      ),
                      const SizedBox(height: 12),
                      const SparkleDivider(),
                      const SizedBox(height: 16),
                      Text(
                        'Remember what God has spoken',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.warmGray,
                        ),
                      ),
                    ],
                  ),
                ),

                // Loading dots near the bottom.
                const Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: _LoadingDots(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Three dots: the first gold, the rest sage.
class _LoadingDots extends StatelessWidget {
  const _LoadingDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _dot(AppColors.gold),
        _dot(AppColors.sage),
        _dot(AppColors.sage),
      ],
    );
  }

  Widget _dot(Color color) => Container(
        width: 10,
        height: 10,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
