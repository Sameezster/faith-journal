import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';

/// Screens 2–4 — 3-page carousel: Read the Bible / Save & Reflect / Track Your Prayers.
/// Skip + Next, final page shows "Get Started".
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    (title: 'Read the Bible', body: 'Read the Word in KJV, NIV and Tamil.'),
    (title: 'Save & Reflect', body: 'Save meaningful verses and write your reflections.'),
    (title: 'Track Your Prayers', body: 'Follow each prayer from request to answered.'),
  ];

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;
    return Scaffold(
      backgroundColor: FjColors.cream50,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.all(FjSpacing.xxl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(_pages[i].title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displayLarge),
                      const SizedBox(height: FjSpacing.lg),
                      Text(_pages[i].body,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: FjColors.gray500)),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(FjSpacing.xxl),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                      onPressed: () => context.go('/welcome'),
                      child: const Text('Skip', style: TextStyle(color: FjColors.gray500))),
                  ElevatedButton(
                    onPressed: () => isLast
                        ? context.go('/welcome')
                        : _controller.nextPage(
                            duration: const Duration(milliseconds: 280), curve: Curves.easeOut),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(140, 52)),
                    child: Text(isLast ? 'Get Started' : 'Next'),
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
