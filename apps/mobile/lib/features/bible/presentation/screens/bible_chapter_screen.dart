import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/bible_provider/bible_models.dart';
import '../../../../shared/bible_provider/bible_providers.dart';
import 'verse_action_sheet.dart';

/// Focused reading view for a single Bible chapter.
/// Top bar: back, prev/next, chapter title (tap to pick), translation chip.
/// Below the bar: a thin action toolbar (Chapter · Search · Bookmark · Text).
/// Tap any verse to open the action sheet.
class BibleChapterScreen extends ConsumerStatefulWidget {
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
  ConsumerState<BibleChapterScreen> createState() => _BibleChapterScreenState();
}

class _BibleChapterScreenState extends ConsumerState<BibleChapterScreen> {
  int? _highlightedVerse;
  double _fontScale = 1.0;

  @override
  Widget build(BuildContext context) {
    final chapterAsync = ref.watch(
      bibleChapterProvider(widget.translation, widget.book, widget.chapter),
    );
    final booksAsync = ref.watch(booksProvider(widget.translation));
    final bookMeta = booksAsync.value?.findByOsis(widget.book);

    return Scaffold(
      backgroundColor: FjColors.cream50,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              translation: widget.translation,
              currentChapter: widget.chapter,
              bookName:
                  chapterAsync.value?.bookName ?? bookMeta?.name ?? widget.book,
              bookMeta: bookMeta,
              onJumpChapter: (n) => context.go(
                '/bible/${widget.translation}/${widget.book}/$n',
              ),
              onBack: () => context.go('/bible'),
            ),
            _ActionToolbar(
              onChapter: () {
                if (bookMeta != null) {
                  _openChapterPicker(context, bookMeta);
                }
              },
              onSearch: () => context.go('/bible/search'),
              onBookmark: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bookmarks — coming soon.')),
              ),
              onText: _openTextSizeSheet,
            ),
            Expanded(
              child: chapterAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorView(
                  error: e,
                  onRetry: () => ref.invalidate(
                    bibleChapterProvider(
                      widget.translation,
                      widget.book,
                      widget.chapter,
                    ),
                  ),
                ),
                data: (c) => _VerseList(
                  chapter: c,
                  highlightedVerse: _highlightedVerse,
                  fontScale: _fontScale,
                  onTapVerse: (v) => _openVerseSheet(c, v),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openVerseSheet(Chapter c, Verse v) {
    setState(() => _highlightedVerse = v.number);
    showVerseActionSheet(
      context,
      translation: widget.translation,
      book: widget.book,
      chapter: widget.chapter,
      verseNumber: v.number,
      verseReference: '${c.bookName} ${c.chapter}:${v.number}',
      verseText: v.text,
    ).whenComplete(() {
      if (mounted) setState(() => _highlightedVerse = null);
    });
  }

  Future<void> _openTextSizeSheet() async {
    final picked = await showModalBottomSheet<double>(
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
                FjSpacing.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Text size',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: FjColors.navy900,
                  ),
                ),
              ),
            ),
            for (final entry in const [
              ('Small', 0.85),
              ('Default', 1.0),
              ('Large', 1.2),
              ('Extra large', 1.4),
            ])
              ListTile(
                title: Text(entry.$1),
                trailing: (_fontScale - entry.$2).abs() < 0.01
                    ? const Icon(Icons.check, color: FjColors.gold500)
                    : null,
                onTap: () => Navigator.pop(ctx, entry.$2),
              ),
            const SizedBox(height: FjSpacing.sm),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _fontScale = picked);
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
                          fontWeight: FontWeight.w700,
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: chapters.length,
                  itemBuilder: (_, i) {
                    final n = chapters[i];
                    final current = n == widget.chapter;
                    return InkWell(
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        if (n != widget.chapter) {
                          context.go(
                            '/bible/${widget.translation}/${widget.book}/$n',
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(FjRadius.chip),
                      child: Container(
                        decoration: BoxDecoration(
                          color: current ? FjColors.gold500 : FjColors.surface0,
                          border: Border.all(
                            color:
                                current ? FjColors.gold500 : FjColors.gray300,
                          ),
                          borderRadius: BorderRadius.circular(FjRadius.chip),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$n',
                          style: TextStyle(
                            color: current ? Colors.white : FjColors.navy900,
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

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.translation,
    required this.currentChapter,
    required this.bookName,
    required this.bookMeta,
    required this.onJumpChapter,
    required this.onBack,
  });

  final String translation;
  final int currentChapter;
  final String bookName;
  final Book? bookMeta;
  final ValueChanged<int> onJumpChapter;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final chapters = bookMeta?.chaptersAvailable ?? [];
    final idx = chapters.indexOf(currentChapter);
    final prev = idx > 0 ? chapters[idx - 1] : null;
    final next =
        idx >= 0 && idx < chapters.length - 1 ? chapters[idx + 1] : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FjSpacing.md,
        FjSpacing.sm,
        FjSpacing.md,
        FjSpacing.md,
      ),
      child: Row(
        children: [
          _CircleIconButton(icon: Icons.arrow_back, onTap: onBack),
          const SizedBox(width: FjSpacing.sm),
          _CircleIconButton(
            icon: Icons.chevron_left,
            onTap: prev == null ? null : () => onJumpChapter(prev),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: bookMeta == null
                  ? null
                  : () {
                      // Title tap opens picker — handled by parent
                    },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$bookName $currentChapter',
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: FjColors.navy900,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down,
                      size: 22, color: FjColors.navy900),
                ],
              ),
            ),
          ),
          _CircleIconButton(
            icon: Icons.chevron_right,
            onTap: next == null ? null : () => onJumpChapter(next),
          ),
          const SizedBox(width: FjSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: FjColors.gold500.withValues(alpha: 0.3)),
              color: FjColors.surface0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  translation,
                  style: const TextStyle(
                    color: FjColors.navy900,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.keyboard_arrow_down,
                    size: 16, color: FjColors.gold500),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: Icon(
          icon,
          color: disabled ? FjColors.gray300 : FjColors.navy900,
          size: 22,
        ),
      ),
    );
  }
}

class _ActionToolbar extends StatelessWidget {
  const _ActionToolbar({
    required this.onChapter,
    required this.onSearch,
    required this.onBookmark,
    required this.onText,
  });

  final VoidCallback onChapter;
  final VoidCallback onSearch;
  final VoidCallback onBookmark;
  final VoidCallback onText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: FjColors.gray300),
          bottom: BorderSide(color: FjColors.gray300),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _ToolbarItem(
              icon: Icons.menu_book_outlined,
              label: 'Chapter',
              onTap: onChapter),
          _ToolbarItem(icon: Icons.search, label: 'Search', onTap: onSearch),
          _ToolbarItem(
              icon: Icons.bookmark_outline,
              label: 'Bookmark',
              onTap: onBookmark),
          _ToolbarItem(icon: Icons.text_fields, label: 'Text', onTap: onText),
        ],
      ),
    );
  }
}

class _ToolbarItem extends StatelessWidget {
  const _ToolbarItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: FjColors.navy700, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: FjColors.navy700,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerseList extends StatelessWidget {
  const _VerseList({
    required this.chapter,
    required this.highlightedVerse,
    required this.fontScale,
    required this.onTapVerse,
  });

  final Chapter chapter;
  final int? highlightedVerse;
  final double fontScale;
  final ValueChanged<Verse> onTapVerse;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        FjSpacing.gutter,
        FjSpacing.lg,
        FjSpacing.gutter,
        FjSpacing.xxxl,
      ),
      itemCount: chapter.verses.length,
      itemBuilder: (_, i) {
        final v = chapter.verses[i];
        final isHighlighted = v.number == highlightedVerse;
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onTapVerse(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: FjSpacing.md),
            padding: const EdgeInsets.symmetric(
              horizontal: FjSpacing.md,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? FjColors.gold500.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 17 * fontScale,
                  height: 1.55,
                  color: FjColors.navy900,
                ),
                children: [
                  TextSpan(
                    text: '${v.number}  ',
                    style: TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      color: FjColors.gold500,
                      fontWeight: FontWeight.w700,
                      fontSize: 13 * fontScale,
                    ),
                  ),
                  TextSpan(text: v.text),
                ],
              ),
            ),
          ),
        );
      },
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
            const Icon(Icons.error_outline, color: FjColors.gray500, size: 48),
            const SizedBox(height: FjSpacing.md),
            Text(
              'Could not load this chapter.\n$error',
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
