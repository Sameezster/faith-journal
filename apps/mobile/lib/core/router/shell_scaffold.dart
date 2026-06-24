import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/tokens.dart';

/// Bottom navigation shell: Home · Bible · Journal · Prayer · Profile.
/// Active tab uses navy icon/label with a gold indicator (per the design).
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({required this.shell, super.key});
  final StatefulNavigationShell shell;

  static const _items = [
    (icon: Icons.home_outlined, label: 'Home'),
    (icon: Icons.menu_book_outlined, label: 'Bible'),
    (icon: Icons.bookmark_border, label: 'Journal'),
    (icon: Icons.volunteer_activism_outlined, label: 'Prayer'),
    (icon: Icons.person_outline, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: FjColors.surface0,
          indicatorColor: FjColors.gold300.withOpacity(0.35),
          labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
                fontSize: 11,
                color: s.contains(WidgetState.selected)
                    ? FjColors.navy900
                    : FjColors.gray500,
              )),
        ),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: [
            for (final it in _items)
              NavigationDestination(icon: Icon(it.icon), label: it.label),
          ],
        ),
      ),
    );
  }
}
