import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/bible_provider/bible_book_icons.dart';
import '../../../../shared/bible_provider/bible_models.dart';
import '../../../../shared/bible_provider/bible_providers.dart';

/// Bible browser: title + translation chip, search bar, OT/NT tabs, book list.
class BibleBrowserScreen extends ConsumerWidget {
  const BibleBrowserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translation = ref.watch(selectedTranslationProvider);
    final translations = ref.watch(translationsProvider);
    final books = ref.watch(booksProvider(translation));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: FjColors.cream50,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  FjSpacing.gutter,
                  FjSpacing.lg,
                  FjSpacing.gutter,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Bible',
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                    ),
                    translations.when(
                      loading: () => const _TranslationChipSkeleton(),
                      error: (_, __) => _TranslationChip(
                        code: translation,
                        onTap: null,
                      ),
                      data: (list) => _TranslationChip(
                        code: translation,
                        onTap: () => _pickTranslation(context, ref, list),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FjSpacing.lg),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: FjSpacing.gutter),
                child: _SearchBar(),
              ),
              const SizedBox(height: FjSpacing.lg),
              const TabBar(
                labelColor: FjColors.gold500,
                unselectedLabelColor: FjColors.navy700,
                indicatorColor: FjColors.gold500,
                indicatorWeight: 3,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                tabs: [
                  Tab(text: 'Old Testament'),
                  Tab(text: 'New Testament'),
                ],
              ),
              Expanded(
                child: books.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _ErrorView(
                    message: 'Could not load books.',
                    onRetry: () => ref.invalidate(booksProvider(translation)),
                  ),
                  data: (list) => TabBarView(
                    children: [
                      _BookList(
                        books: list.oldTestament,
                        translation: translation,
                      ),
                      _BookList(
                        books: list.newTestament,
                        translation: translation,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTranslation(
    BuildContext context,
    WidgetRef ref,
    List<Translation> list,
  ) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: FjColors.surface0,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(FjRadius.cardLg)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                FjSpacing.gutter,
                FjSpacing.lg,
                FjSpacing.gutter,
                FjSpacing.md,
              ),
              child: Row(
                children: [
                  Text(
                    'Choose translation',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: FjColors.navy900,
                    ),
                  ),
                ],
              ),
            ),
            for (final t in list)
              ListTile(
                title: Text(t.code),
                subtitle: Text(t.name),
                trailing: ref.read(selectedTranslationProvider) == t.code
                    ? const Icon(Icons.check, color: FjColors.gold500)
                    : null,
                onTap: () => Navigator.pop(ctx, t.code),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      ref.read(selectedTranslationProvider.notifier).set(picked);
    }
  }
}

class _TranslationChip extends StatelessWidget {
  const _TranslationChip({required this.code, required this.onTap});
  final String code;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FjColors.surface0,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: FjColors.gold500.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                code,
                style: const TextStyle(
                  color: FjColors.navy900,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down,
                  size: 18, color: FjColors.gold500),
            ],
          ),
        ),
      ),
    );
  }
}

class _TranslationChipSkeleton extends StatelessWidget {
  const _TranslationChipSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 36,
      decoration: BoxDecoration(
        color: FjColors.surface0,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FjColors.gray300),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        height: 14,
        width: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FjColors.surface0,
      borderRadius: BorderRadius.circular(FjRadius.input),
      child: InkWell(
        borderRadius: BorderRadius.circular(FjRadius.input),
        onTap: () => context.go('/bible/search'),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: FjSpacing.lg,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(FjRadius.input),
            boxShadow: [
              BoxShadow(
                color: FjColors.navy900.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: FjColors.gray500),
              SizedBox(width: FjSpacing.md),
              Expanded(
                child: Text(
                  'Search books or verses',
                  style: TextStyle(color: FjColors.gray500, fontSize: 14),
                ),
              ),
              Icon(Icons.tune, color: FjColors.gold500),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookList extends StatelessWidget {
  const _BookList({required this.books, required this.translation});

  final List<Book> books;
  final String translation;

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(FjSpacing.xxl),
          child: Text(
            'No books in this section yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: FjColors.gray500),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        FjSpacing.gutter,
        FjSpacing.md,
        FjSpacing.gutter,
        FjSpacing.xxxl,
      ),
      itemCount: books.length,
      separatorBuilder: (_, __) => const SizedBox(height: FjSpacing.sm),
      itemBuilder: (_, i) =>
          _BookCard(book: books[i], translation: translation),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book, required this.translation});

  final Book book;
  final String translation;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FjColors.surface0,
      borderRadius: BorderRadius.circular(FjRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(FjRadius.card),
        onTap: () => context.go(
          '/bible/$translation/${book.osisCode}/${book.firstChapter}',
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(FjRadius.card),
            boxShadow: [
              BoxShadow(
                color: FjColors.navy900.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: FjSpacing.md,
            vertical: FjSpacing.md,
          ),
          child: Row(
            children: [
              Icon(
                bibleBookIcon(book.osisCode),
                color: FjColors.gold500,
                size: 26,
              ),
              const SizedBox(width: FjSpacing.md),
              Expanded(
                child: Text(
                  book.name,
                  style: const TextStyle(
                    color: FjColors.navy900,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: FjColors.gray500),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FjSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: FjColors.gray500),
            ),
            const SizedBox(height: FjSpacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
