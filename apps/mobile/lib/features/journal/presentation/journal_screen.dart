import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/journal/journal_entry.dart';
import '../../../shared/journal/journal_providers.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            FjSpacing.gutter,
            FjSpacing.gutter,
            FjSpacing.gutter,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Journal',
                  style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: FjSpacing.lg),
              Expanded(
                child: async.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(FjSpacing.lg),
                      child: Text('Could not load entries.\n$e',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: FjColors.gray500)),
                    ),
                  ),
                  data: (entries) => entries.isEmpty
                      ? const _EmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 96),
                          itemCount: entries.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: FjSpacing.md),
                          itemBuilder: (_, i) => _EntryCard(entry: entries[i]),
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

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.go('/journal/${entry.id}'),
        borderRadius: BorderRadius.circular(FjRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(FjSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.createdAt != null)
                Text(
                  _formatDate(entry.createdAt!),
                  style: const TextStyle(
                    color: FjColors.gray500,
                    fontSize: 12,
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                entry.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
              if (entry.categories.isNotEmpty) ...[
                const SizedBox(height: FjSpacing.md),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: entry.categories
                      .map((c) => Chip(
                            label: Text(c, style: const TextStyle(fontSize: 12)),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    return '${months[d.month - 1]} ${d.day}, ${d.year}  ·  $h:$m $ampm';
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
