import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/widgets/home_bottom_nav.dart';

/// Bottom navigation shell: Home · Bible · Journal · Prayer · Profile.
/// Uses the client-design [HomeBottomNav] (constant navy icons; only the
/// active label turns gold and gains a short underline).
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({required this.shell, super.key});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: HomeBottomNav(
        currentIndex: shell.currentIndex,
        onTap: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}
