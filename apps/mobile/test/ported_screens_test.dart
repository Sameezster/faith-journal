import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:faith_journal/core/theme/app_theme.dart';
import 'package:faith_journal/features/auth/domain/auth_repository.dart';
import 'package:faith_journal/features/auth/presentation/providers/auth_providers.dart';
import 'package:faith_journal/features/auth/presentation/screens/login_screen.dart';
import 'package:faith_journal/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:faith_journal/features/auth/presentation/screens/register_screen.dart';
import 'package:faith_journal/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:faith_journal/features/auth/presentation/screens/welcome_screen.dart';
import 'package:faith_journal/features/bible/presentation/screens/bible_browser_screen.dart';
import 'package:faith_journal/features/bible/presentation/screens/bible_chapter_screen.dart';
import 'package:faith_journal/features/bible/presentation/screens/saved_verses_screen.dart';
import 'package:faith_journal/features/home/presentation/home_screen.dart';
import 'package:faith_journal/features/home/presentation/widgets/home_bottom_nav.dart';
import 'package:faith_journal/features/profile/presentation/providers/profile_providers.dart';
import 'package:faith_journal/shared/bible_provider/bible_models.dart';
import 'package:faith_journal/shared/bible_provider/bible_providers.dart';
import 'package:faith_journal/shared/bible_provider/bible_repository.dart';
import 'package:faith_journal/shared/journal/journal_entry.dart';
import 'package:faith_journal/shared/journal/journal_providers.dart';

/// Serves canned Bible content for any request — lets the ported screens
/// build with realistic data without the FastAPI backend.
class _FakeBibleRepository implements BibleRepository {
  static const _john = Book(
    osisCode: 'John',
    name: 'John',
    order: 43,
    chapterCount: 21,
    chapterNumbers: [1, 2, 3, 4, 5],
  );
  static const _gen = Book(
    osisCode: 'Gen',
    name: 'Genesis',
    order: 1,
    chapterCount: 50,
    chapterNumbers: [1, 2, 3],
  );

  @override
  Future<List<Translation>> getTranslations() async => const [
        Translation(
            code: 'KJV',
            name: 'King James Version',
            language: 'en',
            license: 'PD',
            source: 'bundled'),
        Translation(
            code: 'WEB',
            name: 'World English Bible',
            language: 'en',
            license: 'PD',
            source: 'bundled'),
      ];

  @override
  Future<BookList> getBooks(String translation) async => const BookList(
        translation: 'KJV',
        oldTestament: [_gen],
        newTestament: [_john],
      );

  @override
  Future<Chapter> getChapter(String translation, String book, int chapter) async =>
      Chapter(
        translation: translation,
        bookCode: book,
        bookName: book == 'Gen' ? 'Genesis' : 'John',
        chapter: chapter,
        verses: const [
          Verse(number: 1, text: 'In the beginning was the Word.'),
          Verse(
              number: 16,
              text:
                  'For God so loved the world, that he gave his only begotten Son.'),
        ],
      );

  @override
  Future<List<SearchHit>> search(String query,
          {String? translation, int? limit}) async =>
      const [];
}

const _user = AppUser(uid: 'u1', email: 'sam@test.dev', displayName: 'Sam');

final _entries = [
  JournalEntry(
    id: 'e1',
    type: JournalEntryType.verse,
    text: 'God is faithful in every season.',
    categories: const ['hope', 'faith'],
    verseRef: 'KJV:Isa:41:10',
    verseReference: 'Isaiah 41:10',
    verseText: 'Fear thou not; for I am with thee.',
    createdAt: DateTime(2026, 5, 8),
  ),
  JournalEntry(
    id: 'e2',
    type: JournalEntryType.text,
    text: "I'm learning to give my worries to God in prayer.",
    categories: const ['peace'],
    createdAt: DateTime(2026, 5, 7),
  ),
];

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      bibleRepositoryProvider.overrideWithValue(_FakeBibleRepository()),
      authStateProvider.overrideWith((ref) => Stream.value(_user)),
      userProfileProvider.overrideWith((ref) => Stream.value(null)),
      journalEntriesProvider.overrideWith((ref) => Stream.value(_entries)),
    ],
    child: MaterialApp(theme: AppTheme.light, home: child),
  );
}

Future<void> _pumpAndSettle(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(_wrap(child));
  // Let streams/futures resolve; avoid pumpAndSettle because the home screen
  // shows spinners while async providers load.
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('Ported client-design screens build without exceptions', () {
    testWidgets('HomeScreen renders greeting, verse card, quick actions',
        (tester) async {
      await _pumpAndSettle(tester, const HomeScreen());
      expect(find.textContaining(', Sam'), findsOneWidget);
      expect(find.text('Verse of the Day'), findsOneWidget);
      expect(find.text('Bible'), findsOneWidget);
      expect(find.text('Journal'), findsOneWidget);
      expect(find.text('Recent Reflections'), findsOneWidget);
      expect(find.text('Isaiah 41:10'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('HomeBottomNav shows the 5 design tabs', (tester) async {
      int tapped = -1;
      await tester.pumpWidget(_wrap(Scaffold(
        bottomNavigationBar:
            HomeBottomNav(currentIndex: 0, onTap: (i) => tapped = i),
      )));
      await tester.pump();
      for (final label in ['Home', 'Bible', 'Journal', 'Prayer', 'Profile']) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.tap(find.text('Bible'));
      expect(tapped, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('BibleBrowserScreen lists books with testament tabs',
        (tester) async {
      await _pumpAndSettle(tester, const BibleBrowserScreen());
      expect(find.text('Old Testament'), findsOneWidget);
      expect(find.text('New Testament'), findsOneWidget);
      expect(find.text('Genesis'), findsOneWidget); // OT tab active by default
      // Switch to NT.
      await tester.tap(find.text('New Testament'));
      await tester.pump();
      expect(find.text('John'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('BibleChapterScreen renders verses and tool row',
        (tester) async {
      await _pumpAndSettle(
        tester,
        const BibleChapterScreen(translation: 'KJV', book: 'John', chapter: 3),
      );
      expect(find.text('John 3'), findsOneWidget);
      expect(find.text('Chapter'), findsOneWidget);
      expect(find.text('Bookmark'), findsOneWidget);
      expect(find.textContaining('For God so loved the world'), findsOneWidget);
      // Tap a verse → slim action bar appears.
      await tester.tap(find.textContaining('In the beginning'));
      await tester.pump();
      expect(find.text('Highlight'), findsOneWidget);
      expect(find.text('Note'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SavedVersesScreen shows verse cards with tags',
        (tester) async {
      await _pumpAndSettle(tester, const SavedVersesScreen());
      expect(find.text('Saved Verses'), findsOneWidget);
      expect(find.text('Isaiah 41:10'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Hope'), findsNWidgets(2)); // filter chip + card tag
      expect(tester.takeException(), isNull);
    });

    testWidgets('Auth + welcome + onboarding screens build', (tester) async {
      await _pumpAndSettle(tester, const LoginScreen());
      expect(find.text('Welcome Back'), findsOneWidget);

      await _pumpAndSettle(tester, const RegisterScreen());
      expect(find.text('Create Account'), findsOneWidget);

      await _pumpAndSettle(tester, const ResetPasswordScreen());
      expect(find.text('Reset Password'), findsOneWidget);

      await _pumpAndSettle(tester, const WelcomeScreen());
      expect(find.text('Get Started'), findsOneWidget);

      await _pumpAndSettle(tester, const OnboardingScreen());
      expect(find.text('Read the Bible'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
