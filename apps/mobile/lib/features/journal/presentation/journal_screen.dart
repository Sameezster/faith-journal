import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/journal/journal_entry.dart';
import '../../../shared/journal/journal_providers.dart';

/// Time-window filter for the journal timeline.
enum JournalFilter { today, week, month, all }

extension on JournalFilter {
  String get label => switch (this) {
        JournalFilter.today => 'Today',
        JournalFilter.week => 'This Week',
        JournalFilter.month => 'This Month',
        JournalFilter.all => 'All Time',
      };
}

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  JournalFilter _filter = JournalFilter.week;

  bool _inWindow(DateTime? d) {
    if (d == null) return _filter == JournalFilter.all;
    final now = DateTime.now();
    return switch (_filter) {
      JournalFilter.today => DateTime(d.year, d.month, d.day) ==
          DateTime(now.year, now.month, now.day),
      JournalFilter.week => d.isAfter(now.subtract(const Duration(days: 7))),
      JournalFilter.month => d.isAfter(now.subtract(const Duration(days: 30))),
      JournalFilter.all => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(journalEntriesProvider);

    return Scaffold(
      backgroundColor: FjColors.cream50,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/journal/new'),
        backgroundColor: FjColors.gold500,
        foregroundColor: Colors.white,
        child: const Icon(Icons.edit_outlined),
      ),
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
                      'My Journal',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                  ),
                  _HeaderIconButton(
                    icon: Icons.filter_alt_outlined,
                    onTap: () => _showFilterSheet(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: FjSpacing.lg),
            _FilterPills(
              selected: _filter,
              onChanged: (f) => setState(() => _filter = f),
            ),
            const SizedBox(height: FjSpacing.md),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(FjSpacing.lg),
                    child: Text(
                      'Could not load entries.\n$e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: FjColors.gray500),
                    ),
                  ),
                ),
                data: (all) {
                  final filtered =
                      all.where((e) => _inWindow(e.createdAt)).toList();
                  if (filtered.isEmpty) return const _EmptyState();
                  return _Timeline(entries: filtered);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFilterSheet(BuildContext context) async {
    final picked = await showModalBottomSheet<JournalFilter>(
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
            const SizedBox(height: FjSpacing.md),
            for (final f in JournalFilter.values)
              ListTile(
                title: Text(f.label),
                trailing: _filter == f
                    ? const Icon(Icons.check, color: FjColors.gold500)
                    : null,
                onTap: () => Navigator.pop(ctx, f),
              ),
            const SizedBox(height: FjSpacing.sm),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _filter = picked);
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

class _FilterPills extends StatelessWidget {
  const _FilterPills({required this.selected, required this.onChanged});
  final JournalFilter selected;
  final ValueChanged<JournalFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: FjSpacing.gutter),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: FjColors.gray300.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: JournalFilter.values
            .map((f) => Expanded(
                child: _Pill(
                    filter: f, selected: selected, onTap: () => onChanged(f))))
            .toList(),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.filter,
    required this.selected,
    required this.onTap,
  });
  final JournalFilter filter;
  final JournalFilter selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = filter == selected;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? FjColors.gold500 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          filter.label,
          style: TextStyle(
            color: isSelected ? Colors.white : FjColors.navy700,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// The timeline view — a date header above each day's entries, with a
/// type-coded round icon ("spine icon") to the left of every card.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.entries});
  final List<JournalEntry> entries;

  @override
  Widget build(BuildContext context) {
    // Group entries by day. Map preserves insertion order; entries come in
    // newest-first, so the grouped output is newest-first too.
    final groups = <String, List<JournalEntry>>{};
    for (final e in entries) {
      final key = _dateKey(e.createdAt);
      groups.putIfAbsent(key, () => []).add(e);
    }

    final children = <Widget>[];
    for (final entry in groups.entries) {
      children.add(_DateHeader(label: entry.key));
      for (final je in entry.value) {
        children.add(_TimelineRow(entry: je));
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        FjSpacing.gutter,
        FjSpacing.sm,
        FjSpacing.gutter,
        96,
      ),
      children: children,
    );
  }

  static String _dateKey(DateTime? d) {
    if (d == null) return 'Undated';
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

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: FjSpacing.md, bottom: FjSpacing.sm),
      child: Text(
        label,
        style: const TextStyle(
          color: FjColors.sage500,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry});
  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FjSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SpineIcon(type: entry.type),
          const SizedBox(width: FjSpacing.md),
          Expanded(child: _EntryCard(entry: entry)),
        ],
      ),
    );
  }
}

class _SpineIcon extends StatelessWidget {
  const _SpineIcon({required this.type});
  final JournalEntryType type;

  Color get _color => switch (type) {
        JournalEntryType.verse => FjColors.gold500,
        JournalEntryType.text => FjColors.sage500,
        JournalEntryType.voice => FjColors.gold500,
      };

  IconData get _icon => switch (type) {
        JournalEntryType.verse => Icons.bookmark,
        JournalEntryType.text => Icons.edit_outlined,
        JournalEntryType.voice => Icons.mic_none_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(_icon, color: _color, size: 18),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});
  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    return Material(
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
          child: switch (entry.type) {
            JournalEntryType.verse => _VerseBody(entry: entry),
            JournalEntryType.voice => _VoiceBody(entry: entry),
            JournalEntryType.text => _TextBody(entry: entry),
          },
        ),
      ),
    );
  }
}

class _VerseBody extends StatelessWidget {
  const _VerseBody({required this.entry});
  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final title = entry.verseReference ?? 'Saved verse';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bookmark, size: 18, color: FjColors.gold500),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
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
        _CategoryAndLabelRow(
          categories: entry.categories,
          rightLabel: 'Saved Verse',
        ),
      ],
    );
  }
}

class _TextBody extends StatelessWidget {
  const _TextBody({required this.entry});
  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final time = entry.createdAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.edit_outlined, size: 18, color: FjColors.sage500),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Reflection',
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: FjColors.navy900,
                ),
              ),
            ),
            if (time != null) ...[
              Text(
                _formatTime(time),
                style: const TextStyle(
                  color: FjColors.gray500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
            ],
            const Icon(Icons.more_horiz, size: 18, color: FjColors.gray500),
          ],
        ),
        if (entry.verseReference != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.bookmark, size: 12, color: FjColors.gold500),
              const SizedBox(width: 4),
              Text(
                entry.verseReference!,
                style: const TextStyle(
                  color: FjColors.gold500,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
        if (entry.text.isNotEmpty) ...[
          const SizedBox(height: FjSpacing.sm),
          Text(
            entry.text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FjColors.navy900,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: FjSpacing.md),
        _CategoryAndLabelRow(
          categories: entry.categories,
          rightLabel: 'Text Reflection',
        ),
      ],
    );
  }

  static String _formatTime(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }
}

class _VoiceBody extends StatelessWidget {
  const _VoiceBody({required this.entry});
  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final duration = entry.voiceDurationSeconds ?? 0;
    final mm = (duration ~/ 60).toString();
    final ss = (duration % 60).toString().padLeft(2, '0');
    final time = entry.createdAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.mic_none_outlined,
                size: 18, color: FjColors.gold500),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Voice Reflection',
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: FjColors.navy900,
                ),
              ),
            ),
            if (time != null) ...[
              Text(
                _formatTime(time),
                style: const TextStyle(
                  color: FjColors.gray500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
            ],
            const Icon(Icons.more_horiz, size: 18, color: FjColors.gray500),
          ],
        ),
        const SizedBox(height: FjSpacing.md),
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: FjColors.gold500.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.play_arrow,
                  color: FjColors.gold500, size: 26),
            ),
            const SizedBox(width: FjSpacing.md),
            const Expanded(child: _Waveform()),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              '$mm:$ss',
              style: const TextStyle(
                color: FjColors.navy700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const Text(
              'Voice Note',
              style: TextStyle(
                color: FjColors.gold500,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _formatTime(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }
}

/// Static decorative waveform — until real audio recording lands, all
/// voice entries render the same bar pattern.
class _Waveform extends StatelessWidget {
  const _Waveform();

  // 50 deterministic bar heights so the layout looks the same every build.
  static const List<double> _heights = [
    0.3,
    0.5,
    0.7,
    0.4,
    0.6,
    0.8,
    0.5,
    0.3,
    0.4,
    0.6,
    0.7,
    0.9,
    0.7,
    0.5,
    0.4,
    0.3,
    0.5,
    0.6,
    0.7,
    0.5,
    0.3,
    0.4,
    0.6,
    0.8,
    0.7,
    0.5,
    0.4,
    0.6,
    0.7,
    0.5,
    0.3,
    0.5,
    0.7,
    0.9,
    0.7,
    0.5,
    0.3,
    0.4,
    0.6,
    0.5,
    0.3,
    0.4,
    0.6,
    0.7,
    0.5,
    0.3,
    0.4,
    0.5,
    0.6,
    0.4,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _heights
            .map(
              (h) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0.5),
                  child: Container(
                    height: 36 * h,
                    decoration: BoxDecoration(
                      color: FjColors.gold500,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CategoryAndLabelRow extends StatelessWidget {
  const _CategoryAndLabelRow({
    required this.categories,
    required this.rightLabel,
  });

  final List<String> categories;
  final String rightLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: categories.map(_CategoryChip.new).toList(),
          ),
        ),
        Text(
          rightLabel,
          style: const TextStyle(
            color: FjColors.gold500,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip(this.slug);
  final String slug;

  /// Maps a category slug to a (icon, color) pair. Unknown slugs fall back
  /// to a neutral leaf icon in sage.
  ({IconData icon, Color color}) get _style => switch (slug) {
        'faith' => (icon: Icons.eco_outlined, color: FjColors.sage500),
        'hope' => (icon: Icons.anchor, color: FjColors.gold500),
        'strength' => (icon: Icons.shield_outlined, color: FjColors.sage500),
        'love' => (icon: Icons.favorite_outline, color: FjColors.gold500),
        'peace' => (icon: Icons.spa_outlined, color: FjColors.sage500),
        'wisdom' => (icon: Icons.lightbulb_outline, color: FjColors.gold500),
        'prayer' => (
            icon: Icons.volunteer_activism_outlined,
            color: FjColors.gold500
          ),
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
            const Icon(Icons.menu_book_outlined,
                size: 64, color: FjColors.gray300),
            const SizedBox(height: FjSpacing.lg),
            Text(
              'Start your first reflection',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: FjSpacing.sm),
            const Text(
              'Tap the pencil to capture what God has been speaking to you.',
              style: TextStyle(color: FjColors.gray500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
