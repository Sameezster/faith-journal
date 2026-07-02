import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/journal/journal_entry.dart';
import '../../../../shared/journal/journal_providers.dart';

/// A tag that can be attached to a saved verse (and used as a filter).
///
/// [accent] tags (e.g. Hope) render in gold; the rest render in sage.
class _VerseTagStyle {
  const _VerseTagStyle(this.slug, this.label, this.icon, {this.accent = false});

  final String slug;
  final String label;
  final IconData icon;
  final bool accent;
}

// Canonical tag set — shared by the filter row and the per-verse chips.
const List<_VerseTagStyle> _allTags = [
  _VerseTagStyle('faith', 'Faith', LucideIcons.leaf),
  _VerseTagStyle('hope', 'Hope', LucideIcons.anchor, accent: true),
  _VerseTagStyle('healing', 'Healing', LucideIcons.heart),
  _VerseTagStyle('strength', 'Strength', LucideIcons.shield),
  _VerseTagStyle('wisdom', 'Wisdom', LucideIcons.bookOpen),
  _VerseTagStyle('peace', 'Peace', LucideIcons.sparkle),
];

_VerseTagStyle _tagFor(String slug) => _allTags.firstWhere(
      (t) => t.slug == slug,
      orElse: () => _VerseTagStyle(
        slug,
        slug.isEmpty ? slug : '${slug[0].toUpperCase()}${slug.substring(1)}',
        LucideIcons.tag,
      ),
    );

enum _Sort { newest, oldest, book }

/// Saved Verses — the verses the user has bookmarked, filterable by tag.
/// Backed by journal entries of `type == verse`.
class SavedVersesScreen extends ConsumerStatefulWidget {
  const SavedVersesScreen({super.key});

  @override
  ConsumerState<SavedVersesScreen> createState() => _SavedVersesScreenState();
}

class _SavedVersesScreenState extends ConsumerState<SavedVersesScreen> {
  // null = "All"; otherwise the selected filter tag slug.
  String? _filter;
  _Sort _sort = _Sort.newest;

  List<JournalEntry> _visible(List<JournalEntry> all) {
    // Entries arrive newest-first, so index 0 == most recent.
    var list = all
        .where((e) => e.type == JournalEntryType.verse)
        .where((e) => _filter == null || e.categories.contains(_filter))
        .toList();
    switch (_sort) {
      case _Sort.newest:
        break; // already newest-first
      case _Sort.oldest:
        list = list.reversed.toList();
      case _Sort.book:
        list.sort(
            (a, b) => (a.verseReference ?? '').compareTo(b.verseReference ?? ''));
    }
    return list;
  }

  Future<void> _openSort() async {
    final picked = await showModalBottomSheet<_Sort>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _SortSheet(current: _sort),
    );
    if (picked != null) setState(() => _sort = picked);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(journalEntriesProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/profile');
                      }
                    },
                    icon:
                        const Icon(AppIcons.backArrow, color: AppColors.navy),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text('Saved Verses',
                        style: AppTextStyles.h1.copyWith(fontSize: 30)),
                  ),
                  _FilterButton(onTap: _openSort),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Tag filter row.
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  for (final t in _allTags) ...[
                    const SizedBox(width: 10),
                    _FilterChip(
                      label: t.label,
                      icon: t.icon,
                      selected: _filter == t.slug,
                      onTap: () => setState(() => _filter = t.slug),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Verse cards.
            Expanded(
              child: async.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load saved verses.\n$e',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.warmGray),
                    ),
                  ),
                ),
                data: (all) {
                  final verses = _visible(all);
                  if (verses.isEmpty) return const _EmptyState();
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: verses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 18),
                    itemBuilder: (_, i) => _VerseCard(entry: verses[i]),
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

// ---------------------------------------------------------------------------
// Header filter button
// ---------------------------------------------------------------------------
class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.champagne.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
        ),
        child: const Icon(AppIcons.filterFunnel,
            size: 22, color: AppColors.gold),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sort bottom sheet
// ---------------------------------------------------------------------------
class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.current});

  final _Sort current;

  static const _options = [
    (_Sort.newest, 'Newest first', AppIcons.calendar),
    (_Sort.oldest, 'Oldest first', AppIcons.clock),
    (_Sort.book, 'By book', AppIcons.bible),
  ];

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
            Text('Sort by', style: AppTextStyles.h2.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            for (final (value, label, icon) in _options)
              _SortRow(
                icon: icon,
                label: label,
                selected: value == current,
                onTap: () => Navigator.of(context).pop(value),
              ),
          ],
        ),
      ),
    );
  }
}

class _SortRow extends StatelessWidget {
  const _SortRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Icon(icon,
                size: 20, color: selected ? AppColors.gold : AppColors.navy),
            const SizedBox(width: 14),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: selected ? AppColors.gold : AppColors.navy,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(AppIcons.check, size: 20, color: AppColors.gold),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tag filter chip
// ---------------------------------------------------------------------------
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.gold
              : AppColors.champagne.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? AppColors.gold
                : AppColors.sage.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 16,
                  color: selected ? AppColors.white : AppColors.sage),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                fontSize: 14.5,
                color: selected ? AppColors.white : AppColors.navy,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Verse card
// ---------------------------------------------------------------------------
class _VerseCard extends StatelessWidget {
  const _VerseCard({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/journal/${entry.id}'),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reference + reflection icon.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.bookmark, size: 26, color: AppColors.gold),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(entry.verseReference ?? 'Saved verse',
                        style: AppTextStyles.h1.copyWith(fontSize: 24)),
                  ),
                ),
                if (entry.text.isNotEmpty)
                  Icon(AppIcons.noteLines,
                      size: 20, color: AppColors.sage.withValues(alpha: 0.9)),
              ],
            ),
            const SizedBox(height: 12),

            // Verse text.
            if (entry.verseText != null)
              Text(
                entry.verseText!,
                style: AppTextStyles.body.copyWith(
                  fontSize: 16,
                  height: 1.5,
                  color: AppColors.charcoal.withValues(alpha: 0.9),
                ),
              ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 14),

            // Tags — wrap onto a new line only if they genuinely don't fit,
            // so a pill and the date can never overlap.
            if (entry.categories.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final slug in entry.categories)
                    _CardTag(tag: _tagFor(slug)),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // Date on its own right-aligned line.
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _formatDate(entry.createdAt),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.warmGray,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime? d) {
    if (d == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _CardTag extends StatelessWidget {
  const _CardTag({required this.tag});

  final _VerseTagStyle tag;

  @override
  Widget build(BuildContext context) {
    final accent = tag.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: accent
            ? AppColors.gold.withValues(alpha: 0.14)
            : AppColors.sage.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent
              ? AppColors.gold.withValues(alpha: 0.5)
              : AppColors.sage.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tag.icon,
              size: 14, color: accent ? AppColors.gold : AppColors.sage),
          const SizedBox(width: 6),
          Text(
            tag.label,
            style: AppTextStyles.body.copyWith(
              fontSize: 13,
              color: accent ? AppColors.gold : AppColors.navy,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(AppIcons.bookmark,
                size: 64, color: AppColors.placeholder),
            const SizedBox(height: 18),
            Text(
              'No saved verses yet',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap any verse in the Bible reader to save it here.',
              style: AppTextStyles.body.copyWith(color: AppColors.warmGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
