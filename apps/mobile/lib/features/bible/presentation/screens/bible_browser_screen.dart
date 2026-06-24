import 'package:flutter/material.dart';
import 'package:faith_journal/core/theme/tokens.dart';

/// Screen 10 — Bible browser: version dropdown, OT/NT tabs, book list.
class BibleBrowserScreen extends StatelessWidget {
  const BibleBrowserScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FjColors.cream50,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(FjSpacing.gutter),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Bible', style: Theme.of(context).textTheme.displayLarge),
            SizedBox(height: FjSpacing.lg),
            const Expanded(child: Center(child: Text('TODO: build per design (see docs §17)'))),
          ]),
        ),
      ),
    );
  }
}
