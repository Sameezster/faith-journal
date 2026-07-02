import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/bible_provider/bible_models.dart';
import '../../../shared/bible_provider/bible_providers.dart';
import '../../../shared/journal/journal_entry.dart';
import '../../../shared/journal/journal_providers.dart';

const List<({String slug, String label, IconData icon, Color color})>
    _suggestedTopics = [
  (
    slug: 'hope',
    label: 'Hope',
    icon: Icons.anchor,
    color: FjColors.gold500,
  ),
  (
    slug: 'faith',
    label: 'Faith',
    icon: Icons.eco_outlined,
    color: FjColors.sage500,
  ),
  (
    slug: 'fear',
    label: 'Fear',
    icon: Icons.shield_outlined,
    color: FjColors.sage500,
  ),
  (
    slug: 'anxiety',
    label: 'Anxiety',
    icon: Icons.cloud_outlined,
    color: FjColors.sage500,
  ),
  (
    slug: 'healing',
    label: 'Healing',
    icon: Icons.favorite_outline,
    color: FjColors.sage500,
  ),
  (
    slug: 'prayer',
    label: 'Prayer',
    icon: Icons.volunteer_activism_outlined,
    color: FjColors.gold500,
  ),
];

/// Universal search across saved verses, reflections, and voice notes.
/// Bible-wide verse search is also available from the search bar — it queries
/// the API as the user types.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FjColors.cream50,
      // Search is a full-screen route (not a bottom-nav tab), so it needs its
      // own back affordance.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const BackButton(),
        title: const Text('Search'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            FjSpacing.gutter,
            FjSpacing.lg,
            FjSpacing.gutter,
            FjSpacing.xxxl,
          ),
          children: [
            _SearchBar(
              controller: _controller,
              onChanged: _onChanged,
              onClear: () {
                _controller.clear();
                _onChanged('');
              },
            ),
            const SizedBox(height: FjSpacing.lg),
            const _SectionHeader('Suggested Topics'),
            const SizedBox(height: FjSpacing.sm),
            _SuggestedTopics(
              selectedQuery: _query,
              onPick: (slug) {
                _controller.text = slug;
                _onChanged(slug);
              },
            ),
            const SizedBox(height: FjSpacing.xxl),
            _VersesSection(query: _query),
            const SizedBox(height: FjSpacing.xxl),
            _ReflectionsSection(query: _query),
            const SizedBox(height: FjSpacing.xxl),
            _VoiceNotesSection(query: _query),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: FjSpacing.lg),
      decoration: BoxDecoration(
        color: FjColors.surface0,
        borderRadius: BorderRadius.circular(FjRadius.input),
        boxShadow: [
          BoxShadow(
            color: FjColors.navy900.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: FjColors.gray500),
          const SizedBox(width: FjSpacing.md),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: const InputDecoration(
                hintText: 'Search verses, reflections…',
                hintStyle: TextStyle(color: FjColors.gray500),
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (controller.text.isEmpty)
            const Icon(Icons.tune, color: FjColors.gold500)
          else
            IconButton(
              icon: const Icon(Icons.close, color: FjColors.gray500),
              onPressed: onClear,
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
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
        if (onSeeAll != null)
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onSeeAll,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'See All',
                    style: TextStyle(
                      color: FjColors.gold500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 18, color: FjColors.gold500),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SuggestedTopics extends StatelessWidget {
  const _SuggestedTopics({
    required this.selectedQuery,
    required this.onPick,
  });

  final String selectedQuery;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _suggestedTopics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final t = _suggestedTopics[i];
          final isSelected =
              selectedQuery.toLowerCase() == t.slug.toLowerCase();
          return _TopicChip(
            label: t.label,
            icon: t.icon,
            color: t.color,
            selected: isSelected,
            onTap: () => onPick(t.slug),
          );
        },
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.18)
              : color.withValues(alpha: 0.08),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.25),
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersesSection extends ConsumerWidget {
  const _VersesSection({required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query.isEmpty) {
      return const SizedBox.shrink();
    }
    final async = ref.watch(
      bibleSearchProvider(query: query, translation: 'KJV'),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          'Verses',
          onSeeAll: () => context.go('/bible/search'),
        ),
        const SizedBox(height: FjSpacing.md),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(FjSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text(
            'Verse search failed.\n$e',
            style: const TextStyle(color: FjColors.gray500),
          ),
          data: (hits) => hits.isEmpty
              ? const Text(
                  'No verses match.',
                  style: TextStyle(color: FjColors.gray500),
                )
              : Column(
                  children: hits
                      .take(2)
                      .map((h) => _VerseResultCard(hit: h))
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _VerseResultCard extends StatelessWidget {
  const _VerseResultCard({required this.hit});
  final SearchHit hit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FjSpacing.md),
      child: Material(
        color: FjColors.surface0,
        borderRadius: BorderRadius.circular(FjRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(FjRadius.card),
          onTap: () => context.go(
            '/bible/${hit.translation}/${hit.book}/${hit.chapter}',
          ),
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
                        hit.reference,
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
                const SizedBox(height: FjSpacing.sm),
                Text(
                  hit.text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FjColors.navy900,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReflectionsSection extends ConsumerWidget {
  const _ReflectionsSection({required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(journalEntriesProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (all) {
        final lowerQuery = query.toLowerCase();
        final matches =
            all.where((e) => e.type == JournalEntryType.text).where((e) {
          if (query.isEmpty) return true;
          return e.text.toLowerCase().contains(lowerQuery) ||
              e.categories.any((c) => c.toLowerCase().contains(lowerQuery));
        }).toList();
        if (matches.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              'Reflections',
              onSeeAll: () => context.go('/journal'),
            ),
            const SizedBox(height: FjSpacing.md),
            ...matches.take(2).map((e) => _ReflectionResultCard(entry: e)),
          ],
        );
      },
    );
  }
}

class _ReflectionResultCard extends StatelessWidget {
  const _ReflectionResultCard({required this.entry});
  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final date = entry.createdAt;
    final firstTag =
        entry.categories.isNotEmpty ? entry.categories.first : null;
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.edit_outlined,
                    size: 18, color: FjColors.sage500),
                const SizedBox(width: FjSpacing.md),
                Expanded(
                  child: Text(
                    entry.text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FjColors.navy900,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: FjSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (date != null)
                      Text(
                        _formatDate(date),
                        style: const TextStyle(
                          color: FjColors.gray500,
                          fontSize: 12,
                        ),
                      ),
                    if (firstTag != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: FjColors.sage500.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          firstTag[0].toUpperCase() + firstTag.substring(1),
                          style: const TextStyle(
                            color: FjColors.sage500,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
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

class _VoiceNotesSection extends ConsumerWidget {
  const _VoiceNotesSection({required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(journalEntriesProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (all) {
        final voices =
            all.where((e) => e.type == JournalEntryType.voice).toList();
        if (voices.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              'Voice Notes',
              onSeeAll: () => context.go('/journal'),
            ),
            const SizedBox(height: FjSpacing.md),
            ...voices.take(2).map((e) => _VoiceResultCard(entry: e)),
          ],
        );
      },
    );
  }
}

class _VoiceResultCard extends StatelessWidget {
  const _VoiceResultCard({required this.entry});
  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final duration = entry.voiceDurationSeconds ?? 0;
    final mm = (duration ~/ 60).toString();
    final ss = (duration % 60).toString().padLeft(2, '0');
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
            child: Row(
              children: [
                const Icon(Icons.mic_none_outlined,
                    color: FjColors.gold500, size: 22),
                const SizedBox(width: FjSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Voice Reflection',
                        style: TextStyle(
                          color: FjColors.navy900,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 18,
                        decoration: BoxDecoration(
                          color: FjColors.gold500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: FjSpacing.md),
                Text(
                  '$mm:$ss',
                  style: const TextStyle(
                    color: FjColors.navy700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
