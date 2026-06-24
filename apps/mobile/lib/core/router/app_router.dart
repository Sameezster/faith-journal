import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/bible/presentation/screens/bible_browser_screen.dart';
import '../../features/journal/presentation/journal_screen.dart';
import '../../features/prayer/presentation/prayers_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import 'shell_scaffold.dart';

part 'app_router.g.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// GoRouter with a StatefulShellRoute for the 5-tab bottom nav
/// (Home · Bible · Journal · Prayer · Profile). Auth/onboarding live outside the shell.
@riverpod
GoRouter router(RouterRef ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/reset-password', builder: (_, __) => const ResetPasswordScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => ShellScaffold(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/bible', builder: (_, __) => const BibleBrowserScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/journal', builder: (_, __) => const JournalScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/prayer', builder: (_, __) => const PrayersScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
    // TODO: redirect based on authStateProvider (signed-in -> /home, else -> /welcome).
  );
}
