import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../auth/presentation/providers/auth_providers.dart';

/// One configurable reminder. Stored at
/// `users/{uid}/settings/reminders.{slug} = {enabled, hour, minute}`.
class _ReminderDef {
  const _ReminderDef({
    required this.slug,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.defaultHour,
    required this.defaultMinute,
  });

  final String slug;
  final String title;
  final IconData icon;
  final Color iconColor;
  final int defaultHour;
  final int defaultMinute;
}

const List<_ReminderDef> _defs = [
  _ReminderDef(
    slug: 'bible_reading',
    title: 'Bible Reading Reminder',
    icon: Icons.menu_book_outlined,
    iconColor: FjColors.sage500,
    defaultHour: 7,
    defaultMinute: 0,
  ),
  _ReminderDef(
    slug: 'reflection',
    title: 'Reflection Reminder',
    icon: Icons.book_outlined,
    iconColor: FjColors.gold500,
    defaultHour: 21,
    defaultMinute: 0,
  ),
  _ReminderDef(
    slug: 'verse_review',
    title: 'Verse Review',
    icon: Icons.search,
    iconColor: FjColors.sage500,
    defaultHour: 12,
    defaultMinute: 0,
  ),
  _ReminderDef(
    slug: 'prayer',
    title: 'Prayer Reminder',
    icon: Icons.volunteer_activism_outlined,
    iconColor: FjColors.gold500,
    defaultHour: 6,
    defaultMinute: 0,
  ),
];

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  /// Mirrors what's in Firestore. Map of `slug -> (enabled, hour, minute)`.
  /// Initialized from defaults, then overlaid with the user's saved settings.
  late Map<String, ({bool enabled, int hour, int minute})> _state;

  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _state = {
      for (final d in _defs)
        d.slug: (
          enabled: d.slug != 'verse_review',
          hour: d.defaultHour,
          minute: d.defaultMinute,
        ),
    };
    _load();
  }

  Future<void> _load() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    try {
      final snap = await _docRef(user.uid).get();
      if (!mounted) return;
      if (snap.exists) {
        final data = snap.data() ?? const {};
        setState(() {
          for (final d in _defs) {
            final saved = data[d.slug] as Map<String, dynamic>?;
            if (saved != null) {
              _state[d.slug] = (
                enabled: saved['enabled'] as bool? ?? _state[d.slug]!.enabled,
                hour: (saved['hour'] as num?)?.toInt() ?? _state[d.slug]!.hour,
                minute: (saved['minute'] as num?)?.toInt() ??
                    _state[d.slug]!.minute,
              );
            }
          }
        });
      }
    } catch (_) {/* keep defaults */}
    if (mounted) setState(() => _loaded = true);
  }

  DocumentReference<Map<String, dynamic>> _docRef(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('reminders');

  Future<void> _persist() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final payload = {
      for (final entry in _state.entries)
        entry.key: {
          'enabled': entry.value.enabled,
          'hour': entry.value.hour,
          'minute': entry.value.minute,
        },
      'updatedAt': FieldValue.serverTimestamp(),
    };
    try {
      await _docRef(user.uid).set(payload, SetOptions(merge: true));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    }
  }

  Future<void> _toggle(String slug, bool value) async {
    setState(() {
      final cur = _state[slug]!;
      _state[slug] = (enabled: value, hour: cur.hour, minute: cur.minute);
    });
    await _persist();
  }

  Future<void> _pickTime(_ReminderDef def) async {
    final cur = _state[def.slug]!;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: cur.hour, minute: cur.minute),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _state[def.slug] = (
        enabled: cur.enabled,
        hour: picked.hour,
        minute: picked.minute,
      );
    });
    await _persist();
  }

  static String _formatTime(int hour, int minute) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final ampm = hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FjColors.cream50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: FjColors.gold500),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
      ),
      body: SafeArea(
        top: false,
        child: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  FjSpacing.gutter,
                  0,
                  FjSpacing.gutter,
                  FjSpacing.xxxl,
                ),
                children: [
                  const _Header(),
                  const SizedBox(height: FjSpacing.xxl),
                  for (final d in _defs) ...[
                    _ReminderCard(
                      def: d,
                      state: _state[d.slug]!,
                      onToggle: (v) => _toggle(d.slug, v),
                      onTapTime: () => _pickTime(d),
                    ),
                    const SizedBox(height: FjSpacing.md),
                  ],
                ],
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _HeaderIllustration(),
        SizedBox(height: FjSpacing.md),
        Text(
          'Reminders',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.w700,
            fontSize: 32,
            color: FjColors.navy900,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Stay consistent in your walk with God.',
          style: TextStyle(color: FjColors.gray500, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _HeaderIllustration extends StatelessWidget {
  const _HeaderIllustration();

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
            child: Icon(Icons.auto_awesome, size: 18, color: FjColors.gold500),
          ),
          Positioned(
            top: 14,
            child: Icon(Icons.notifications_outlined,
                size: 36, color: FjColors.gold500),
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

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.def,
    required this.state,
    required this.onToggle,
    required this.onTapTime,
  });

  final _ReminderDef def;
  final ({bool enabled, int hour, int minute}) state;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTapTime;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.symmetric(
        horizontal: FjSpacing.lg,
        vertical: FjSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: def.iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(def.icon, color: def.iconColor, size: 26),
          ),
          const SizedBox(width: FjSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  def.title,
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: FjColors.navy900,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: state.enabled ? onTapTime : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: FjColors.sage500.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _RemindersScreenState._formatTime(
                          state.hour, state.minute),
                      style: const TextStyle(
                        color: FjColors.sage500,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: state.enabled,
            onChanged: onToggle,
            activeThumbColor: Colors.white,
            activeTrackColor: FjColors.gold500,
          ),
        ],
      ),
    );
  }
}
