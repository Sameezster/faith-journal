import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/bible_provider/bible_models.dart';
import '../../../../shared/bible_provider/bible_providers.dart';

/// Focused reading view for a single Bible chapter.
/// Full-screen — no bottom nav, so the reader has room to breathe.
/// App bar title is tappable: opens a chapter picker.
/// Bottom bar has Prev / Next buttons that walk within the same book.
class BibleChapterScreen extends ConsumerWidget {
  const BibleChapterScreen({
    super.key,
    required this.translation,
    required this.book,
    required this.chapter,
  });

  final String translation;
  final String book;
  final int chapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapterAsync =
        ref.watch(bibleChapterProvider(translation, book, chapter));
    final booksAsync = ref.watch(booksProvider(translation));
    final bookMeta = booksAsync.value?.findByOsis(book);

    return Scaffold(
      backgroundColor: FjColors.cream50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/bible'),
        ),
        title: _TitleButton(
          bookName: chapterAsync.value?.bookName ?? bookMeta?.name ?? book,
          chapter: chapter,
          enabled: bookMeta != null,
          onTap: () => _openChapterPicker(context, bookMeta!),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: FjSpacing.md),
            child: Center(
              child: Text(
                translation,
                style: const TextStyle(
                  color: FjColors.gold500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: bookMeta == null
          ? null
          : _PrevNextBar(
              book: bookMeta,
              currentChapter: chapter,
              onJump: (target) =>
                  context.go('/bible/$translation/$book/$target'),
            ),
      body: SafeArea(
        bottom: false,
        child: chapterAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(
            error: e,
            onRetry: () => ref.invalidate(
              bibleChapterProvider(translation, book, chapter),
            ),
          ),
          data: (c) => ListView.builder(
            padding: const EdgeInsets.all(FjSpacing.gutter),
            itemCount: c.verses.length,
            itemBuilder: (_, i) {
              final v = c.verses[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: FjSpacing.md),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.55,
                      color: FjColors.navy900,
                    ),
                    children: [
                      TextSpan(
                        text: '${v.number}  ',
                        style: const TextStyle(
                          color: FjColors.gold500,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      TextSpan(text: v.text),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _openChapterPicker(BuildContext context, Book bookMeta) {
    final chapters = bookMeta.chaptersAvailable;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: FjColors.surface0,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(FjRadius.cardLg)),
      ),
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  FjSpacing.gutter,
                  FjSpacing.lg,
                  FjSpacing.gutter,
                  FjSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${bookMeta.name} — pick a chapter',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: FjColors.navy900,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: FjColors.gray300),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(FjSpacing.gutter),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: chapters.length,
                  itemBuilder: (_, i) {
                    final n = chapters[i];
                    final current = n == chapter;
                    return InkWell(
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        if (n != chapter) {
                          context.go('/bible/$translation/$book/$n');
                        }
                      },
                      borderRadius: BorderRadius.circular(FjRadius.chip),
                      child: Container(
                        decoration: BoxDecoration(
                          color: current
                              ? FjColors.gold500
                              : FjColors.surface0,
                          border: Border.all(
                            color: current
                                ? FjColors.gold500
                                : FjColors.gray300,
                          ),
                          borderRadius:
                              BorderRadius.circular(FjRadius.chip),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$n',
                          style: TextStyle(
                            color: current
                                ? Colors.white
                                : FjColors.navy900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TitleButton extends StatelessWidget {
  const _TitleButton({
    required this.bookName,
    required this.chapter,
    required this.enabled,
    required this.onTap,
  });

  final String bookName;
  final int chapter;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(FjRadius.chip),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                '$bookName $chapter',
                style: const TextStyle(
                  color: FjColors.navy900,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (enabled) ...[
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, color: FjColors.navy700),
            ],
          ],
        ),
      ),
    );
  }
}

class _PrevNextBar extends StatelessWidget {
  const _PrevNextBar({
    required this.book,
    required this.currentChapter,
    required this.onJump,
  });

  final Book book;
  final int currentChapter;
  final ValueChanged<int> onJump;

  @override
  Widget build(BuildContext context) {
    final chapters = book.chaptersAvailable;
    final idx = chapters.indexOf(currentChapter);
    final prev = idx > 0 ? chapters[idx - 1] : null;
    final next =
        idx >= 0 && idx < chapters.length - 1 ? chapters[idx + 1] : null;

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: FjColors.surface0,
          border: Border(top: BorderSide(color: FjColors.gray300)),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: FjSpacing.gutter,
          vertical: FjSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: prev == null ? null : () => onJump(prev),
                icon: const Icon(Icons.chevron_left),
                label: Text(prev == null ? 'Start' : 'Chapter $prev'),
              ),
            ),
            Text(
              '${book.name} $currentChapter / ${chapters.length}',
              style: const TextStyle(
                color: FjColors.gray500,
                fontSize: 12,
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: next == null ? null : () => onJump(next),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.chevron_right),
                label: Text(next == null ? 'End' : 'Chapter $next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FjSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: FjColors.gray500, size: 48),
            const SizedBox(height: FjSpacing.md),
            Text('Could not load this chapter.\n$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: FjColors.gray500)),
            const SizedBox(height: FjSpacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
