import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';

/// Screen 9 — Home: greeting, Verse of the Day, quick-action grid, recent reflections.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FjColors.cream50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(FjSpacing.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good morning',
                  style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: FjSpacing.lg),
              const Expanded(
                  child: Center(
                      child: Text('TODO: build per design (see docs §17)'))),
            ],
          ),
        ),
      ),
    );
  }
}
