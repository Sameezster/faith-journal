import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/tokens.dart';

/// Screen 5 — Welcome to Faith Journal. Get Started -> register; Sign in -> login.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(FjSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_book, size: 64, color: FjColors.navy900),
              const SizedBox(height: FjSpacing.lg),
              Text(
                'Welcome to\nFaith Journal',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: FjSpacing.sm),
              const Text(
                'Your personal spiritual memory companion',
                style: TextStyle(color: FjColors.gray500),
              ),
              const SizedBox(height: FjSpacing.xxxl),
              ElevatedButton(
                onPressed: () => context.go('/register'),
                child: const Text('Get Started'),
              ),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Already have an account? Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
