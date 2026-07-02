import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/bible_provider/bible_book_icons.dart';
import '../../../../shared/bible_provider/bible_models.dart';
import '../../../../shared/bible_provider/bible_providers.dart';

/// Bible — books list. Header with version selector, a search bar, Old/New
/// Testament tabs and a scrollable list of books.
class BibleBrowserScreen extends ConsumerStatefulWidget {
  const BibleBrowserScreen({super.key});

  @override
  ConsumerState<BibleBrowserScreen> createState() =>
      _BibleBrowserScreenState();
}

class _BibleBrowserScreenState extends ConsumerState<BibleBrowserScreen> {
  int _tab = 0; // 0 = Old Testament, 1 = New Testament

  @override
  Widget build(BuildContext context) {
    final translation = ref.watch(selectedTranslationProvider);
    final translations = ref.watch(translationsProvider);
    final books = ref.watch(booksProvider(translation));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Text('Bible', style: AppTextStyles.h1.copyWith(fontSize: 30)),
                  const Spacer(),
                  _VersionDropdown(
                    value: translation,
                    options: translations.value?.map((t) => t.code).toList() ??
                        [translation],
                    onChanged: (v) =>
                        ref.read(selectedTranslationProvider.notifier).set(v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search bar.
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _SearchBar(),
            ),
            const SizedBox(height: 20),

            // Tabs.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _TestamentTab(
                    label: 'Old Testament',
                    active: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                  ),
                  _TestamentTab(
                    label: 'New Testament',
                    active: _tab == 1,
                    onTap: () => setState(() => _tab = 1),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: AppColors.divider),

            // Books list.
            Expanded(
              child: books.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorView(
                  message: 'Could not load books.',
                  onRetry: () => ref.invalidate(booksProvider(translation)),
                ),
                data: (list) {
                  final visible =
                      _tab == 0 ? list.oldTestament : list.newTestament;
                  if (visible.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'No books in this section yet.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.warmGray),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) =>
                        _BookRow(book: visible[i], translation: translation),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionDropdown extends StatelessWidget {
  const _VersionDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      initialValue: value,
      color: AppColors.white,
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      itemBuilder: (_) => [
        for (final v in options)
          PopupMenuItem<String>(
            value: v,
            child: Row(
              children: [
                Text(
                  v,
                  style: AppTextStyles.body.copyWith(
                    color: v == value ? AppColors.gold : AppColors.navy,
                    fontWeight:
                        v == value ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (v == value) ...[
                  const Spacer(),
                  const Icon(AppIcons.forward, size: 16, color: AppColors.gold),
                ],
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.champagne.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                style: AppTextStyles.chip.copyWith(
                    color: AppColors.navy, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(AppIcons.chevronDown, size: 18, color: AppColors.navy),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // The real search experience lives on its own screen.
      onTap: () => context.push('/bible/search'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(AppIcons.search, size: 20, color: AppColors.warmGray),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search books or verses',
                style: AppTextStyles.body.copyWith(color: AppColors.placeholder),
              ),
            ),
            const Icon(AppIcons.filter, size: 20, color: AppColors.sage),
          ],
        ),
      ),
    );
  }
}

class _TestamentTab extends StatelessWidget {
  const _TestamentTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: active ? AppColors.gold : AppColors.warmGray,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            Container(
              height: 2.5,
              color: active ? AppColors.gold : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

class _BookRow extends StatelessWidget {
  const _BookRow({required this.book, required this.translation});

  final Book book;
  final String translation;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go(
          '/bible/$translation/${book.osisCode}/${book.firstChapter}',
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(bibleBookIcon(book.osisCode),
                  size: 24, color: AppColors.gold),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  book.name,
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.navy, fontSize: 17),
                ),
              ),
              const Icon(AppIcons.forward,
                  size: 20, color: AppColors.placeholder),
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.warmGray),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
