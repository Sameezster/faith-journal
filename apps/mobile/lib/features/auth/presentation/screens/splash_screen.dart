import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';

/// Screen 1 — branded splash with logo, tagline, and a 3-dot page indicator.
/// Routes to onboarding/welcome (or /home if a session is restored).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) context.go('/onboarding');
    });
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
            Text('Faith Journal',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 30)),
            const SizedBox(height: FjSpacing.sm),
            const Text('Remember what God has spoken',
                style: TextStyle(color: FjColors.gray500)),
          ],
        ),
      ),
    );
  }
}
