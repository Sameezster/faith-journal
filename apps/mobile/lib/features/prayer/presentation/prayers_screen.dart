import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';

/// Screen 17 — Prayers: status filter chips, prayer cards, FAB to add.
class PrayersScreen extends StatelessWidget {
  const PrayersScreen({super.key});
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
              Text('Prayers', style: Theme.of(context).textTheme.displayLarge),
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
