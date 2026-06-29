import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/prayer/prayer_categories.dart';
import '../../../shared/prayer/prayer_providers.dart';
import '../../../shared/prayer/prayer_request.dart';
import '../../auth/presentation/providers/auth_providers.dart';

/// Filter applied to the prayer list. `null` = show all.
class PrayersScreen extends ConsumerStatefulWidget {
  const PrayersScreen({super.key});

  @override
  ConsumerState<PrayersScreen> createState() => _PrayersScreenState();
}

class _PrayersScreenState extends ConsumerState<PrayersScreen> {
  PrayerStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(prayerRequestsProvider);

    return Scaffold(
      backgroundColor: FjColors.cream50,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/prayer/new'),
        backgroundColor: FjColors.gold500,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 28),
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
                      'Prayers',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                  ),
                  Container(
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
                    child: const Icon(
                      Icons.volunteer_activism_outlined,
                      color: FjColors.gold500,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: FjSpacing.lg),
            _FilterChips(
              selected: _filter,
              onChanged: (s) => setState(() => _filter = s),
            ),
            const SizedBox(height: FjSpacing.lg),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(FjSpacing.lg),
                    child: Text(
                      'Could not load prayers.\n$e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: FjColors.gray500),
                    ),
                  ),
                ),
                data: (list) {
                  final filtered = _filter == null
                      ? list
                      : list.where((p) => p.status == _filter).toList();
                  if (filtered.isEmpty) return const _EmptyState();
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      FjSpacing.gutter,
                      0,
                      FjSpacing.gutter,
                      96,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _PrayerCard(prayer: filtered[i]),
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

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onChanged});

  final PrayerStatus? selected;
  final ValueChanged<PrayerStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: FjSpacing.gutter),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            icon: null,
            color: FjColors.gold500,
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 10),
          _FilterChip(
            label: 'Active',
            icon: Icons.eco_outlined,
            color: FjColors.statusActive,
            selected: selected == PrayerStatus.active,
            onTap: () => onChanged(PrayerStatus.active),
          ),
          const SizedBox(width: 10),
          _FilterChip(
            label: 'Waiting',
            icon: Icons.hourglass_empty,
            color: FjColors.statusWaiting,
            selected: selected == PrayerStatus.waiting,
            onTap: () => onChanged(PrayerStatus.waiting),
          ),
          const SizedBox(width: 10),
          _FilterChip(
            label: 'Answered',
            icon: Icons.check_circle_outline,
            color: FjColors.statusAnswered,
            selected: selected == PrayerStatus.answered,
            onTap: () => onChanged(PrayerStatus.answered),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerCard extends ConsumerWidget {
  const _PrayerCard({required this.prayer});
  final PrayerRequest prayer;

  Color _statusColor(PrayerStatus s) => switch (s) {
        PrayerStatus.active => FjColors.statusActive,
        PrayerStatus.waiting => FjColors.statusWaiting,
        PrayerStatus.answered => FjColors.statusAnswered,
      };

  IconData _statusIcon(PrayerStatus s) => switch (s) {
        PrayerStatus.active => Icons.circle,
        PrayerStatus.waiting => Icons.hourglass_empty,
        PrayerStatus.answered => Icons.check_circle_outline,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = findPrayerCategory(prayer.category);
    final statusColor = _statusColor(prayer.status);
    final date = prayer.displayDate;

    return Padding(
      padding: const EdgeInsets.only(bottom: FjSpacing.md),
      child: Material(
        color: FjColors.surface0,
        borderRadius: BorderRadius.circular(FjRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(FjRadius.card),
          onTap: () => context.go('/prayer/${prayer.id}'),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FjRadius.card),
              boxShadow: [
                BoxShadow(
                  color: FjColors.navy900.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(FjSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CategoryBubble(category: cat),
                const SizedBox(width: FjSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              prayer.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'PlayfairDisplay',
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: FjColors.navy900,
                              ),
                            ),
                          ),
                          _CardMenuButton(prayer: prayer),
                        ],
                      ),
                      if (prayer.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          prayer.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: FjColors.navy700,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: FjSpacing.md),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (cat != null) _CategoryChip(category: cat),
                          if (date != null) _DateChip(date: date),
                          _StatusChip(
                            label: prayer.status.label,
                            color: statusColor,
                            icon: _statusIcon(prayer.status),
                          ),
                        ],
                      ),
                    ],
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

class _CategoryBubble extends StatelessWidget {
  const _CategoryBubble({required this.category});
  final PrayerCategoryDef? category;

  @override
  Widget build(BuildContext context) {
    final cat = category;
    final icon = cat?.icon ?? Icons.volunteer_activism_outlined;
    final color = cat?.color ?? FjColors.gold500;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});
  final PrayerCategoryDef category;

  @override
  Widget build(BuildContext context) {
    return _MetaChip(
      icon: category.icon,
      label: category.label,
      color: category.color,
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return _MetaChip(
      icon: Icons.calendar_today_outlined,
      label: _formatDate(date),
      color: FjColors.gray500,
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.icon,
  });
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardMenuButton extends ConsumerWidget {
  const _CardMenuButton({required this.prayer});
  final PrayerRequest prayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, color: FjColors.gray500),
      onSelected: (value) => _onSelect(context, ref, value),
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        if (prayer.status != PrayerStatus.active)
          const PopupMenuItem(value: 'active', child: Text('Mark active')),
        if (prayer.status != PrayerStatus.waiting)
          const PopupMenuItem(value: 'waiting', child: Text('Mark waiting')),
        if (prayer.status != PrayerStatus.answered)
          const PopupMenuItem(value: 'answered', child: Text('Mark answered')),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }

  Future<void> _onSelect(
      BuildContext context, WidgetRef ref, String value) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final repo = ref.read(prayerRepositoryProvider);

    switch (value) {
      case 'edit':
        context.go('/prayer/${prayer.id}');
        return;
      case 'active':
        await repo.updateRequest(user.uid, prayer.id,
            status: PrayerStatus.active);
        return;
      case 'waiting':
        await repo.updateRequest(user.uid, prayer.id,
            status: PrayerStatus.waiting);
        return;
      case 'answered':
        await repo.updateRequest(user.uid, prayer.id,
            status: PrayerStatus.answered);
        return;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete prayer?'),
            content: const Text('This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await repo.deleteRequest(user.uid, prayer.id);
        }
        return;
    }
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
            const Icon(
              Icons.volunteer_activism_outlined,
              size: 64,
              color: FjColors.gray300,
            ),
            const SizedBox(height: FjSpacing.lg),
            Text(
              'Lift your heart',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: FjSpacing.sm),
            const Text(
              'Tap the + to write your first prayer request.',
              style: TextStyle(color: FjColors.gray500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
