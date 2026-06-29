import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/journal/journal_entry.dart';
import '../../../../shared/journal/journal_providers.dart';

const List<({String slug, String label, IconData icon, Color color})>
    _tagFilters = [
  (
    slug: 'faith',
    label: 'Faith',
    icon: Icons.eco_outlined,
    color: FjColors.sage500,
  ),
  (
    slug: 'hope',
    label: 'Hope',
    icon: Icons.anchor,
    color: FjColors.gold500,
  ),
  (
    slug: 'healing',
    label: 'Healing',
    icon: Icons.favorite_outline,
    color: FjColors.sage500,
  ),
  (
    slug: 'strength',
    label: 'Strength',
    icon: Icons.shield_outlined,
    color: FjColors.sage500,
  ),
  (
    slug: 'wisdom',
    label: 'Wisdom',
    icon: Icons.lightbulb_outline,
    color: FjColors.gold500,
  ),
  (
    slug: 'peace',
    label: 'Peace',
    icon: Icons.spa_outlined,
    color: FjColors.sage500,
  ),
];

/// All-saved-verses view. Filters journal entries down to `type == verse`,
/// with chip-based tag filtering.
class SavedVersesScreen extends ConsumerStatefulWidget {
  const SavedVersesScreen({super.key});

  @override
  ConsumerState<SavedVersesScreen> createState() => _SavedVersesScreenState();
}

class _SavedVersesScreenState extends ConsumerState<SavedVersesScreen> {
  String? _filter; // null = All

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(journalEntriesProvider);

    return Scaffold(
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
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Saved Verses',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                  ),
                  _HeaderIconButton(
                    icon: Icons.filter_alt_outlined,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: FjSpacing.md),
            _TagFilterBar(
              selected: _filter,
              onChanged: (s) => setState(() => _filter = s),
            ),
            const SizedBox(height: FjSpacing.md),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(FjSpacing.lg),
                    child: Text(
                      'Could not load saved verses.\n$e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: FjColors.gray500),
                    ),
                  ),
                ),
                data: (all) {
                  final verses = all
                      .where((e) => e.type == JournalEntryType.verse)
                      .where((e) =>
                          _filter == null || e.categories.contains(_filter))
                      .toList();
                  if (verses.isEmpty) {
                    return const _EmptyState();
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      FjSpacing.gutter,
                      0,
                      FjSpacing.gutter,
                      FjSpacing.xxxl,
                    ),
                    itemCount: verses.length,
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

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: FjColors.surface0,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: FjColors.navy900.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: FjColors.gold500, size: 20),
      ),
    );
  }
}

class _TagFilterBar extends StatelessWidget {
  const _TagFilterBar({required this.selected, required this.onChanged});
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: FjSpacing.gutter),
        children: [
          _Chip(
            label: 'All',
            icon: null,
            color: FjColors.gold500,
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 8),
          ..._tagFilters.expand(
            (t) => [
              _Chip(
                label: t.label,
                icon: t.icon,
                color: t.color,
                selected: selected == t.slug,
                onTap: () => onChanged(t.slug),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : color;
    final bg = selected ? color : color.withValues(alpha: 0.10);
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerseCard extends StatelessWidget {
  const _VerseCard({required this.entry});
  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final title = entry.verseReference ?? 'Saved verse';
    return Padding(
      padding: const EdgeInsets.only(bottom: FjSpacing.md),
      child: Material(
        color: FjColors.surface0,
        borderRadius: BorderRadius.circular(FjRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(FjRadius.card),
          onTap: () => context.go('/journal/${entry.id}'),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FjRadius.card),
              boxShadow: [
                BoxShadow(
                  color: FjColors.navy900.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(FjSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bookmark,
                        size: 18, color: FjColors.gold500),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: FjColors.navy900,
                        ),
                      ),
                    ),
                    const Icon(Icons.menu_book_outlined,
                        size: 18, color: FjColors.sage500),
                  ],
                ),
                if (entry.verseText != null) ...[
                  const SizedBox(height: FjSpacing.sm),
                  Text(
                    entry.verseText!,
                    style: const TextStyle(
                      color: FjColors.navy900,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: FjSpacing.md),
                const Divider(height: 1, color: FjColors.gray300),
                const SizedBox(height: FjSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: entry.categories
                            .map((slug) => _SmallTag(slug: slug))
                            .toList(),
                      ),
                    ),
                    Text(
                      _formatDate(entry.createdAt),
                      style: const TextStyle(
                        color: FjColors.gray500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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

class _SmallTag extends StatelessWidget {
  const _SmallTag({required this.slug});
  final String slug;

  ({IconData icon, Color color}) get _style => switch (slug) {
        'faith' => (icon: Icons.eco_outlined, color: FjColors.sage500),
        'hope' => (icon: Icons.anchor, color: FjColors.gold500),
        'strength' => (icon: Icons.shield_outlined, color: FjColors.sage500),
        'healing' => (icon: Icons.favorite_outline, color: FjColors.sage500),
        'wisdom' => (icon: Icons.lightbulb_outline, color: FjColors.gold500),
        'peace' => (icon: Icons.spa_outlined, color: FjColors.sage500),
        _ => (icon: Icons.eco_outlined, color: FjColors.sage500),
      };

  @override
  Widget build(BuildContext context) {
    final style = _style;
    final label =
        slug.isEmpty ? slug : '${slug[0].toUpperCase()}${slug.substring(1)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 12, color: style.color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: style.color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
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
        padding: const EdgeInsets.all(FjSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_outline,
                size: 64, color: FjColors.gray300),
            const SizedBox(height: FjSpacing.lg),
            Text(
              'No saved verses yet',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: FjSpacing.sm),
            const Text(
              'Tap any verse in the Bible reader to save it here.',
              style: TextStyle(color: FjColors.gray500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
