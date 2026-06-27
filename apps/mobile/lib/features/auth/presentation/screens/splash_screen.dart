import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../providers/auth_providers.dart';

/// Branded splash. Briefly shows the logo, then routes:
///   - authenticated user -> /home
///   - first-time / signed-out user -> /onboarding
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), _decideRoute);
  }

  void _decideRoute() {
    if (!mounted) return;
    final user = ref.read(authStateProvider).value;
    context.go(user == null ? '/onboarding' : '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FjColors.cream50,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book, size: 72, color: FjColors.navy900),
            const SizedBox(height: FjSpacing.lg),
            Text(
              'Faith Journal',
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(fontSize: 30),
            ),
            const SizedBox(height: FjSpacing.sm),
            const Text(
              'Remember what God has spoken',
              style: TextStyle(color: FjColors.gray500),
            ),
          ],
        ),
      ),
    );
  }
}
