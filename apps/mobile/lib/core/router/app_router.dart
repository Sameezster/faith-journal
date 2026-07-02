import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/bible/presentation/screens/bible_browser_screen.dart';
import '../../features/bible/presentation/screens/bible_chapter_screen.dart';
import '../../features/bible/presentation/screens/bible_search_screen.dart';
import '../../features/bible/presentation/screens/saved_verses_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/journal/presentation/journal_editor_screen.dart';
import '../../features/journal/presentation/journal_screen.dart';
import '../../features/journal/presentation/voice_reflection_screen.dart';
import '../../features/prayer/presentation/prayer_detail_screen.dart';
import '../../features/prayer/presentation/prayer_editor_screen.dart';
import '../../features/prayer/presentation/prayers_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/reminders/presentation/reminders_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import 'shell_scaffold.dart';

part 'app_router.g.dart';

final _rootKey = GlobalKey<NavigatorState>();

const _publicRoutes = <String>{
  '/splash',
  '/onboarding',
  '/welcome',
  '/login',
  '/register',
  '/reset-password',
};

/// GoRouter with a StatefulShellRoute for the 5-tab bottom nav
/// (Home · Bible · Journal · Prayer · Profile). Auth/onboarding and Search
/// live outside the shell.
///
/// Redirect logic:
///   - Unauthenticated user on a protected route -> /welcome
///   - Authenticated user on any auth route (except /splash) -> /home
@riverpod
GoRouter router(RouterRef ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      if (authAsync.isLoading) return null; // wait for first auth event
      final user = authAsync.value;
      final loc = state.uri.path;
      final isPublic = _publicRoutes.contains(loc);

      if (user == null && !isPublic) return '/welcome';
      if (user != null && isPublic && loc != '/splash') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
          path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
          path: '/reset-password',
          builder: (_, __) => const ResetPasswordScreen()),
      // Journal editor (full-screen, outside the bottom-nav shell).
      // `?ref=KJV:Book:Chapter:Verse` pre-pins a Bible verse to a new entry.
      GoRoute(
        path: '/journal/new',
        builder: (_, state) => JournalEditorScreen(
          pinnedVerseRef: state.uri.queryParameters['ref'],
        ),
      ),
      GoRoute(
        path: '/journal/voice',
        builder: (_, state) => VoiceReflectionScreen(
          pinnedVerseRef: state.uri.queryParameters['ref'],
        ),
      ),
      GoRoute(
        path: '/journal/:id',
        builder: (_, state) =>
            JournalEditorScreen(entryId: state.pathParameters['id']),
      ),
      // Prayer screens (full-screen, outside the bottom-nav shell).
      GoRoute(
        path: '/prayer/new',
        builder: (_, __) => const PrayerEditorScreen(),
      ),
      GoRoute(
        path: '/prayer/:id/edit',
        builder: (_, state) =>
            PrayerEditorScreen(requestId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/prayer/:id',
        builder: (_, state) =>
            PrayerDetailScreen(requestId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/reminders',
        builder: (_, __) => const RemindersScreen(),
      ),
      // Search (full-screen, outside the bottom-nav shell — the design's
      // bottom nav has 5 tabs; Search is reached from the Home quick actions).
      GoRoute(
        path: '/search',
        builder: (_, __) => const SearchScreen(),
      ),
      // Bible search (full-screen).
      GoRoute(
        path: '/bible/search',
        builder: (_, __) => const BibleSearchScreen(),
      ),
      GoRoute(
        path: '/saved-verses',
        builder: (_, __) => const SavedVersesScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => ShellScaffold(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bible',
                builder: (_, __) => const BibleBrowserScreen(),
                routes: [
                  // Chapter reader lives inside the Bible tab so the bottom
                  // nav stays visible while reading (per the client design).
                  GoRoute(
                    path: ':translation/:book/:chapter',
                    builder: (_, state) => BibleChapterScreen(
                      translation: state.pathParameters['translation']!,
                      book: state.pathParameters['book']!,
                      chapter: int.parse(state.pathParameters['chapter']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/journal', builder: (_, __) => const JournalScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/prayer', builder: (_, __) => const PrayersScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/profile', builder: (_, __) => const ProfileScreen()),
            ],
          ),
        ],
      ),
    ],
  );
}
