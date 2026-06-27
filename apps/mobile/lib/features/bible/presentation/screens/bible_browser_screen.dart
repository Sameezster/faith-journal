import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/bible_provider/bible_models.dart';
import '../../../../shared/bible_provider/bible_providers.dart';

/// Browse-the-Bible screen: translation picker + OT/NT tabs + book list.
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
                  FjSpacing.gutter,
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
                    IconButton(
                      tooltip: 'Search',
                      icon: const Icon(Icons.search),
                      onPressed: () => context.go('/bible/search'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FjSpacing.md),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: FjSpacing.gutter),
                child: translations.when(
                  loading: () => const _TranslationPickerSkeleton(),
                  error: (e, _) =>
                      const _ErrorPill(message: 'Could not load translations'),
                  data: (list) => _TranslationPicker(
                    translations: list,
                    selected: translation,
                    onChanged: (code) => ref
                        .read(selectedTranslationProvider.notifier)
                        .set(code),
                  ),
                ),
              ),
              const SizedBox(height: FjSpacing.md),
              const TabBar(
                labelColor: FjColors.navy900,
                indicatorColor: FjColors.gold500,
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
}

class _TranslationPicker extends StatelessWidget {
  const _TranslationPicker({
    required this.translations,
    required this.selected,
    required this.onChanged,
  });

  final List<Translation> translations;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: FjSpacing.md),
      decoration: BoxDecoration(
        color: FjColors.surface0,
        borderRadius: BorderRadius.circular(FjRadius.input),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          items: translations
              .map(
                (t) => DropdownMenuItem(
                  value: t.code,
                  child: Text('${t.code} · ${t.name}'),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _TranslationPickerSkeleton extends StatelessWidget {
  const _TranslationPickerSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: FjColors.surface0,
        borderRadius: BorderRadius.circular(FjRadius.input),
      ),
      child: const Center(
        child: SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
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
            'No books in this section yet.\nRun `make api.seed` to load full Bible data.',
            textAlign: TextAlign.center,
            style: TextStyle(color: FjColors.gray500),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(FjSpacing.gutter),
      itemCount: books.length,
      separatorBuilder: (_, __) => const SizedBox(height: FjSpacing.sm),
      itemBuilder: (_, i) {
        final b = books[i];
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            title: Text(
              b.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${b.chapterCount} chapter${b.chapterCount == 1 ? '' : 's'}',
              style: const TextStyle(color: FjColors.gray500, fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(
              '/bible/$translation/${b.osisCode}/${b.firstChapter}',
            ),
          ),
        );
      },
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

class _ErrorPill extends StatelessWidget {
  const _ErrorPill({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(FjSpacing.md),
      decoration: BoxDecoration(
        color: FjColors.surface0,
        borderRadius: BorderRadius.circular(FjRadius.input),
      ),
      child: Text(message, style: const TextStyle(color: FjColors.gray500)),
    );
  }
}
