import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/prayer/prayer_categories.dart';
import '../../../shared/prayer/prayer_providers.dart';
import '../../../shared/prayer/prayer_request.dart';
import '../../auth/presentation/providers/auth_providers.dart';

/// Read-mostly prayer detail screen. Three status pills at the top can change
/// the prayer's status; the "Mark Answered" button at the bottom is the
/// primary action.
class PrayerDetailScreen extends ConsumerWidget {
  const PrayerDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(prayerRequestProvider(requestId));

    return Scaffold(
      backgroundColor: FjColors.cream50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: FjColors.gold500),
          onPressed: () => context.go('/prayer'),
        ),
        actions: [
          async.maybeWhen(
            data: (p) =>
                p == null ? const SizedBox.shrink() : _MoreMenu(prayer: p),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(FjSpacing.lg),
              child: Text(
                'Could not load this prayer.\n$e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: FjColors.gray500),
              ),
            ),
          ),
          data: (p) => p == null ? const _NotFound() : _Body(prayer: p),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.prayer});
  final PrayerRequest prayer;

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref,
    PrayerStatus status,
  ) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    try {
      await ref.read(prayerRepositoryProvider).updateRequest(
            user.uid,
            prayer.id,
            status: status,
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = findPrayerCategory(prayer.category);
    final isAnswered = prayer.status == PrayerStatus.answered;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              FjSpacing.gutter,
              0,
              FjSpacing.gutter,
              FjSpacing.lg,
            ),
            children: [
              const _Illustration(),
              const SizedBox(height: FjSpacing.md),
              Text(
                prayer.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  height: 1.2,
                  color: FjColors.navy900,
                ),
              ),
              const SizedBox(height: FjSpacing.md),
              _MetaRow(category: cat, date: prayer.displayDate),
              const SizedBox(height: FjSpacing.lg),
              _StatusPills(
                current: prayer.status,
                onPick: (s) => _changeStatus(context, ref, s),
              ),
              const SizedBox(height: FjSpacing.xxl),
              if (prayer.testimony != null && prayer.testimony!.isNotEmpty)
                _Section(
                  icon: Icons.eco_outlined,
                  iconColor: FjColors.sage500,
                  title: 'Testimony',
                  child: _TestimonyCard(
                    text: prayer.testimony!,
                    verseReference: prayer.verseReference,
                  ),
                ),
              if (prayer.description.isNotEmpty)
                _Section(
                  icon: Icons.book_outlined,
                  iconColor: FjColors.gold500,
                  title: 'Notes',
                  child: _NotesCard(text: prayer.description),
                ),
              if (prayer.voiceUrl != null)
                _Section(
                  icon: Icons.mic_none_outlined,
                  iconColor: FjColors.gold500,
                  title: 'Voice Note',
                  child: _VoiceNoteCard(
                    url: prayer.voiceUrl!,
                    durationSeconds: prayer.voiceDurationSeconds ?? 0,
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            FjSpacing.gutter,
            0,
            FjSpacing.gutter,
            FjSpacing.md,
          ),
          child: _MarkAnsweredButton(
            answered: isAnswered,
            onTap: () => _changeStatus(
              context,
              ref,
              isAnswered ? PrayerStatus.active : PrayerStatus.answered,
            ),
          ),
        ),
      ],
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 120,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            child: Icon(Icons.auto_awesome, size: 20, color: FjColors.gold500),
          ),
          Positioned(
            top: 10,
            child: Icon(Icons.add, size: 32, color: FjColors.gold500),
          ),
          Positioned(
            bottom: 0,
            left: 12,
            child: Icon(Icons.spa_outlined, size: 26, color: FjColors.sage500),
          ),
          Positioned(
            bottom: 0,
            right: 12,
            child: Icon(Icons.spa_outlined, size: 26, color: FjColors.sage500),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.category, required this.date});
  final PrayerCategoryDef? category;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (category != null) {
      children.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category!.icon, size: 14, color: category!.color),
            const SizedBox(width: 4),
            Text(
              category!.label,
              style: TextStyle(
                color: category!.color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }
    if (date != null) {
      if (children.isNotEmpty) {
        children.add(Container(
          width: 1,
          height: 14,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          color: FjColors.gray300,
        ));
      }
      children.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 14, color: FjColors.gray500),
            const SizedBox(width: 4),
            Text(
              _formatDate(date!),
              style: const TextStyle(
                color: FjColors.gray500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
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

class _StatusPills extends StatelessWidget {
  const _StatusPills({required this.current, required this.onPick});
  final PrayerStatus current;
  final ValueChanged<PrayerStatus> onPick;

  static const _items = [
    (status: PrayerStatus.active, icon: Icons.circle, label: 'Active'),
    (
      status: PrayerStatus.waiting,
      icon: Icons.access_time,
      label: 'In Progress',
    ),
    (
      status: PrayerStatus.answered,
      icon: Icons.check_circle_outline,
      label: 'Answered',
    ),
  ];

  Color _color(PrayerStatus s) => switch (s) {
        PrayerStatus.active => FjColors.gold500,
        PrayerStatus.waiting => FjColors.statusWaiting,
        PrayerStatus.answered => FjColors.statusAnswered,
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _items.map((it) {
        final isSelected = it.status == current;
        final color = _color(it.status);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => onPick(it.status),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isSelected ? color : color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isSelected ? color : color.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    it.icon,
                    size: 14,
                    color: isSelected ? Colors.white : color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    it.label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : color,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FjSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: FjColors.navy900,
                ),
              ),
            ],
          ),
          const SizedBox(height: FjSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _TestimonyCard extends StatelessWidget {
  const _TestimonyCard({required this.text, required this.verseReference});
  final String text;
  final String? verseReference;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(FjSpacing.lg),
      decoration: BoxDecoration(
        color: FjColors.surface0,
        borderRadius: BorderRadius.circular(FjRadius.card),
        boxShadow: [
          BoxShadow(
            color: FjColors.navy900.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    color: FjColors.navy900,
                    fontSize: 15,
                    height: 1.55,
                  ),
                ),
                if (verseReference != null) ...[
                  const SizedBox(height: FjSpacing.md),
                  Text(
                    verseReference!,
                    style: const TextStyle(
                      color: FjColors.sage500,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: FjSpacing.md),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: FjColors.sage500.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.flutter_dash, // dove-like silhouette
              color: FjColors.sage500,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(FjSpacing.lg),
      decoration: BoxDecoration(
        color: FjColors.surface0,
        borderRadius: BorderRadius.circular(FjRadius.card),
        boxShadow: [
          BoxShadow(
            color: FjColors.navy900.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: FjColors.navy900,
                fontSize: 15,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(width: FjSpacing.md),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: FjColors.sage500.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.menu_book,
              color: FjColors.sage500,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceNoteCard extends StatefulWidget {
  const _VoiceNoteCard({required this.url, required this.durationSeconds});
  final String url;
  final int durationSeconds;

  @override
  State<_VoiceNoteCard> createState() => _VoiceNoteCardState();
}

class _VoiceNoteCardState extends State<_VoiceNoteCard> {
  final _player = AudioPlayer();
  bool _playing = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _player.playerStateStream.listen((s) {
      if (!mounted) return;
      setState(() => _playing = s.playing);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_loading) return;
    if (_playing) {
      await _player.pause();
      return;
    }
    setState(() => _loading = true);
    try {
      if (_player.duration == null) {
        await _player.setUrl(widget.url);
      }
      await _player.play();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not play: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mm = (widget.durationSeconds ~/ 60).toString();
    final ss = (widget.durationSeconds % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.all(FjSpacing.lg),
      decoration: BoxDecoration(
        color: FjColors.surface0,
        borderRadius: BorderRadius.circular(FjRadius.card),
        boxShadow: [
          BoxShadow(
            color: FjColors.navy900.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            customBorder: const CircleBorder(),
            onTap: _toggle,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: FjColors.sage500.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _playing ? Icons.pause : Icons.play_arrow,
                      color: FjColors.sage500,
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: FjSpacing.md),
          const Expanded(child: _MiniWaveform()),
          const SizedBox(width: FjSpacing.md),
          Text(
            '$mm:$ss',
            style: const TextStyle(
              color: FjColors.navy700,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniWaveform extends StatelessWidget {
  const _MiniWaveform();

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
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _heights
            .map((h) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.5),
                    child: Container(
                      height: 28 * h,
                      decoration: BoxDecoration(
                        color: FjColors.sage500,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _MarkAnsweredButton extends StatelessWidget {
  const _MarkAnsweredButton({required this.answered, required this.onTap});
  final bool answered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: FjColors.gold500,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FjRadius.button),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.volunteer_activism_outlined, size: 20),
          const SizedBox(width: 8),
          Text(
            answered ? 'Reopen Prayer' : 'Mark Answered',
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreMenu extends ConsumerWidget {
  const _MoreMenu({required this.prayer});
  final PrayerRequest prayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, color: FjColors.gold500),
      onSelected: (v) async {
        final user = ref.read(authStateProvider).value;
        if (user == null) return;
        switch (v) {
          case 'edit':
            context.go('/prayer/${prayer.id}/edit');
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
              await ref
                  .read(prayerRepositoryProvider)
                  .deleteRequest(user.uid, prayer.id);
              if (!context.mounted) return;
              context.go('/prayer');
            }
            return;
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuDivider(),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(FjSpacing.xxl),
        child: Text(
          'Prayer not found.',
          style: TextStyle(color: FjColors.gray500),
        ),
      ),
    );
  }
}
