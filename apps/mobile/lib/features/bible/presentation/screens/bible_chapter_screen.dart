import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/bible_provider/bible_models.dart';
import '../../../../shared/bible_provider/bible_providers.dart';
import '../../../../shared/journal/journal_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'verse_action_sheet.dart';

/// Bible — chapter reading view. Comfortable serif scripture with selectable
/// verses, a chapter navigator, a tool row and a slim action bar.
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
  ConsumerState<BibleChapterScreen> createState() =>
      _BibleChapterScreenState();
}

class _BibleChapterScreenState extends ConsumerState<BibleChapterScreen> {
  int? _selected;
  double _fontScale = 1.0;

  void _go(String translation, int chapter) {
    context.go('/bible/$translation/${widget.book}/$chapter');
  }

  Future<void> _pickChapter(Book bookMeta) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ChapterPicker(
        bookName: bookMeta.name,
        chapters: bookMeta.chaptersAvailable,
        selected: widget.chapter,
      ),
    );
    if (picked != null && picked != widget.chapter) {
      _go(widget.translation, picked);
    }
  }

  void _openSheet(Chapter c, Verse v) {
    showVerseActionSheet(
      context,
      translation: widget.translation,
      book: widget.book,
      chapter: widget.chapter,
      verseNumber: v.number,
      verseReference: '${c.bookName} ${c.chapter}:${v.number}',
      verseText: v.text,
    );
  }

  void _onVerseTap(Chapter c, Verse v) {
    if (_selected == v.number) {
      // Second tap on the selected verse → open the full action sheet.
      _openSheet(c, v);
    } else {
      setState(() => _selected = v.number);
    }
  }

  Future<void> _saveVerse(Chapter c, Verse v) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final reference = '${c.bookName} ${c.chapter}:${v.number}';
    try {
      await ref.read(journalRepositoryProvider).createVerseEntry(
            user.uid,
            verseRef:
                '${widget.translation}:${widget.book}:${widget.chapter}:${v.number}',
            verseReference: reference,
            verseText: v.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved $reference to journal.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  Future<void> _shareVerse(Chapter c, Verse v) async {
    final reference = '${c.bookName} ${c.chapter}:${v.number}';
    await Clipboard.setData(ClipboardData(
      text: '"${v.text}"\n— $reference (${widget.translation})',
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard.')),
    );
  }

  void _onSlimAction(Chapter c, String label) {
    final v = c.verses.firstWhere((e) => e.number == _selected);
    switch (label) {
      case 'Save':
        _saveVerse(c, v);
      case 'Note':
        context.go(
          '/journal/new?ref=${widget.translation}:${widget.book}:${widget.chapter}:${v.number}',
        );
      case 'Share':
        _shareVerse(c, v);
      default: // Highlight → full sheet, matching the design.
        _openSheet(c, v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chapterAsync = ref.watch(
      bibleChapterProvider(widget.translation, widget.book, widget.chapter),
    );
    final booksAsync = ref.watch(booksProvider(widget.translation));
    final bookMeta = booksAsync.value?.findByOsis(widget.book);
    final versions = ref.watch(translationsProvider).value?.map((t) => t.code).toList() ??
        [widget.translation];

    final chapters = bookMeta?.chaptersAvailable ?? const <int>[];
    final idx = chapters.indexOf(widget.chapter);
    final prev = idx > 0 ? chapters[idx - 1] : null;
    final next =
        idx >= 0 && idx < chapters.length - 1 ? chapters[idx + 1] : null;

    final bookName =
        chapterAsync.value?.bookName ?? bookMeta?.name ?? widget.book;
    final reference = '$bookName ${widget.chapter}';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(
              reference: reference,
              version: widget.translation,
              versions: versions,
              onBack: () => context.go('/bible'),
              onTapChapter:
                  bookMeta == null ? null : () => _pickChapter(bookMeta),
              onPrev: prev == null
                  ? null
                  : () => _go(widget.translation, prev),
              onNext: next == null
                  ? null
                  : () => _go(widget.translation, next),
              onVersionChanged: (v) {
                ref.read(selectedTranslationProvider.notifier).set(v);
                _go(v, widget.chapter);
              },
            ),
            _ToolRow(
              onChapter:
                  bookMeta == null ? null : () => _pickChapter(bookMeta),
              onSearch: () => context.push('/bible/search'),
              onBookmark: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bookmarks — coming soon.')),
              ),
              onText: _openTextSizeSheet,
            ),

            // Scripture.
            Expanded(
              child: chapterAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
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
                data: (c) => Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(6, 18, 6, 24),
                        itemCount: c.verses.length,
                        itemBuilder: (_, i) {
                          final v = c.verses[i];
                          return _VerseTile(
                            verse: v,
                            fontScale: _fontScale,
                            selected: _selected == v.number,
                            onTap: () => _onVerseTap(c, v),
                            onLongPress: () {
                              setState(() => _selected = v.number);
                              _openSheet(c, v);
                            },
                          );
                        },
                      ),
                    ),

                    // Slim action bar — visible while a verse is selected.
                    if (_selected != null)
                      _SlimActionBar(
                        onAction: (label) => _onSlimAction(c, label),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTextSizeSheet() async {
    final picked = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.placeholder.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Text size', style: AppTextStyles.h2.copyWith(fontSize: 18)),
              const SizedBox(height: 8),
              for (final entry in const [
                ('Small', 0.85),
                ('Default', 1.0),
                ('Large', 1.2),
                ('Extra large', 1.4),
              ])
                InkWell(
                  onTap: () => Navigator.pop(ctx, entry.$2),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 4),
                    child: Row(
                      children: [
                        Text(
                          entry.$1,
                          style: AppTextStyles.body.copyWith(
                            color: (_fontScale - entry.$2).abs() < 0.01
                                ? AppColors.gold
                                : AppColors.navy,
                            fontWeight: (_fontScale - entry.$2).abs() < 0.01
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if ((_fontScale - entry.$2).abs() < 0.01)
                          const Icon(AppIcons.check,
                              size: 20, color: AppColors.gold),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _fontScale = picked);
  }
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.reference,
    required this.version,
    required this.versions,
    required this.onBack,
    required this.onTapChapter,
    required this.onPrev,
    required this.onNext,
    required this.onVersionChanged,
  });

  final String reference;
  final String version;
  final List<String> versions;
  final VoidCallback onBack;
  final VoidCallback? onTapChapter;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final ValueChanged<String> onVersionChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(AppIcons.back, color: AppColors.navy),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _NavArrow(icon: AppIcons.back, onTap: onPrev),
                  Expanded(
                    child: InkWell(
                      onTap: onTapChapter,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                reference,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.h2.copyWith(fontSize: 20),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(AppIcons.chevronDown,
                                size: 20, color: AppColors.navy),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _NavArrow(icon: AppIcons.forward, onTap: onNext),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: onVersionChanged,
            initialValue: version,
            color: AppColors.white,
            offset: const Offset(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            itemBuilder: (_) => [
              for (final v in versions)
                PopupMenuItem<String>(
                  value: v,
                  child: Row(
                    children: [
                      Text(
                        v,
                        style: AppTextStyles.body.copyWith(
                          color:
                              v == version ? AppColors.gold : AppColors.navy,
                          fontWeight:
                              v == version ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      if (v == version) ...[
                        const Spacer(),
                        const Icon(AppIcons.forward,
                            size: 16, color: AppColors.gold),
                      ],
                    ],
                  ),
                ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.champagne.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(version,
                      style: AppTextStyles.chip.copyWith(
                          color: AppColors.navy, fontWeight: FontWeight.w600)),
                  const Icon(AppIcons.chevronDown,
                      size: 16, color: AppColors.navy),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Prev/next chapter arrow — dims when disabled (e.g. prev on chapter 1).
class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 22,
          color: enabled
              ? AppColors.warmGray
              : AppColors.warmGray.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tool row
// ---------------------------------------------------------------------------
class _ToolRow extends StatelessWidget {
  const _ToolRow({
    required this.onChapter,
    required this.onSearch,
    required this.onBookmark,
    required this.onText,
  });

  final VoidCallback? onChapter;
  final VoidCallback onSearch;
  final VoidCallback onBookmark;
  final VoidCallback onText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _Tool(icon: AppIcons.bible, label: 'Chapter', onTap: onChapter),
          _Tool(icon: AppIcons.search, label: 'Search', onTap: onSearch),
          _Tool(icon: AppIcons.bookmark, label: 'Bookmark', onTap: onBookmark),
          _Tool(icon: AppIcons.textSize, label: 'Text', onTap: onText),
        ],
      ),
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.navy),
          const SizedBox(width: 7),
          Text(label,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.charcoal, fontSize: 15)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Verse tile
// ---------------------------------------------------------------------------
class _VerseTile extends StatelessWidget {
  const _VerseTile({
    required this.verse,
    required this.fontScale,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final Verse verse;
  final double fontScale;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey(verse.number),
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      // Padding is identical whether selected or not, so the text never
      // shifts when a verse is highlighted. The highlight toggles instantly
      // (no fade) so switching between verses never cross-fades / blinks.
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.champagne.withValues(alpha: 0.7)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${verse.number} ',
                style: AppTextStyles.scripture.copyWith(
                  fontSize: 13 * fontScale,
                  height: 1.7,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
              TextSpan(
                text: verse.text,
                style: AppTextStyles.scripture
                    .copyWith(fontSize: 18 * fontScale, height: 1.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Slim action bar
// ---------------------------------------------------------------------------
class _SlimActionBar extends StatelessWidget {
  const _SlimActionBar({required this.onAction});

  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _SlimItem(icon: AppIcons.heart, label: 'Save', onTap: onAction),
          _SlimItem(
              icon: AppIcons.reflect, label: 'Highlight', onTap: onAction),
          _SlimItem(icon: AppIcons.noteLines, label: 'Note', onTap: onAction),
          _SlimItem(icon: AppIcons.share, label: 'Share', onTap: onAction),
        ],
      ),
    );
  }
}

class _SlimItem extends StatelessWidget {
  const _SlimItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    // Expanded + FittedBox guarantees the four actions always fit, never
    // overflowing on narrow screens.
    return Expanded(
      child: InkWell(
        onTap: () => onTap(label),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 19, color: AppColors.navy),
                const SizedBox(width: 7),
                Text(label,
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.charcoal, fontSize: 14.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chapter picker
// ---------------------------------------------------------------------------
class _ChapterPicker extends StatelessWidget {
  const _ChapterPicker({
    required this.bookName,
    required this.chapters,
    required this.selected,
  });

  final String bookName;
  final List<int> chapters;
  final int selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.placeholder.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('$bookName — Chapters',
                style: AppTextStyles.h2.copyWith(fontSize: 18)),
            const SizedBox(height: 16),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: chapters.length,
                itemBuilder: (_, i) {
                  final n = chapters[i];
                  final active = n == selected;
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(n),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.gold.withValues(alpha: 0.16)
                            : AppColors.champagne.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: active
                              ? AppColors.gold.withValues(alpha: 0.6)
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        '$n',
                        style: AppTextStyles.body.copyWith(
                          color: active ? AppColors.gold : AppColors.navy,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.warmGray, size: 48),
            const SizedBox(height: 12),
            Text(
              'Could not load this chapter.\n$error',
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
