import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/bible_provider/bible_providers.dart';
import '../../../shared/journal/journal_entry.dart';
import '../../../shared/journal/journal_providers.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../profile/presentation/providers/profile_providers.dart';

/// Curated rotation of well-known verses for the daily "verse of the day".
const List<({String osis, int chapter, int verse})> _verseOfDay = [
  (osis: 'Isa', chapter: 41, verse: 10),
  (osis: 'John', chapter: 3, verse: 16),
  (osis: 'Psa', chapter: 23, verse: 1),
  (osis: 'Jer', chapter: 29, verse: 11),
  (osis: 'Phi', chapter: 4, verse: 13),
  (osis: 'Rom', chapter: 8, verse: 28),
  (osis: 'Pro', chapter: 3, verse: 5),
  (osis: 'Jos', chapter: 1, verse: 9),
  (osis: 'Mat', chapter: 11, verse: 28),
  (osis: 'Psa', chapter: 46, verse: 10),
  (osis: 'Rom', chapter: 12, verse: 2),
  (osis: 'Phi', chapter: 4, verse: 6),
  (osis: '2Co', chapter: 5, verse: 17),
  (osis: 'Gal', chapter: 5, verse: 22),
  (osis: 'John', chapter: 14, verse: 6),
  (osis: 'Psa', chapter: 119, verse: 105),
  (osis: 'Heb', chapter: 11, verse: 1),
  (osis: 'Eph', chapter: 2, verse: 8),
  (osis: 'Psa', chapter: 27, verse: 1),
  (osis: 'Isa', chapter: 40, verse: 31),
  (osis: 'Psa', chapter: 91, verse: 1),
  (osis: 'Mat', chapter: 5, verse: 16),
  (osis: 'Jas', chapter: 1, verse: 5),
  (osis: '1Pe', chapter: 5, verse: 7),
  (osis: 'Psa', chapter: 37, verse: 4),
  (osis: 'Pro', chapter: 16, verse: 3),
  (osis: 'Col', chapter: 3, verse: 23),
  (osis: 'Lam', chapter: 3, verse: 22),
  (osis: '1Co', chapter: 13, verse: 4),
  (osis: 'Rom', chapter: 10, verse: 9),
];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final auth = ref.watch(authStateProvider).value;
    final profile = ref.watch(userProfileProvider).value;
    final entries = ref.watch(journalEntriesProvider);

    final displayName =
        (profile?.displayName ?? auth?.displayName)?.split(' ').first ??
            _emailFirstPart(auth?.email);
    final photoUrl = profile?.photoUrl ?? auth?.photoUrl;

    return Scaffold(
      backgroundColor: FjColors.cream50,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(journalEntriesProvider);
            ref.invalidate(translationsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              FjSpacing.gutter,
              FjSpacing.lg,
              FjSpacing.gutter,
              FjSpacing.xxxl,
            ),
            children: [
              _Greeting(name: displayName, now: now, photoUrl: photoUrl),
              const SizedBox(height: FjSpacing.xxl),
              _VerseOfDayCard(now: now),
              const SizedBox(height: FjSpacing.xxl),
              const _QuickActionGrid(),
              const SizedBox(height: FjSpacing.xxxl),
              _RecentReflectionsHeader(),
              const SizedBox(height: FjSpacing.md),
              entries.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(FjSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text(
                  'Could not load entries.\n$e',
                  style: const TextStyle(color: FjColors.gray500),
                ),
                data: (list) => list.isEmpty
                    ? const _EmptyRecent()
                    : Column(
                        children: list
                            .take(3)
                            .toList()
                            .asMap()
                            .entries
                            .map((e) =>
                                _RecentTile(entry: e.value, index: e.key))
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _emailFirstPart(String? email) {
    if (email == null || email.isEmpty) return 'friend';
    final at = email.indexOf('@');
    final left = at < 0 ? email : email.substring(0, at);
    return left.isEmpty
        ? 'friend'
        : '${left[0].toUpperCase()}${left.substring(1)}';
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.name,
    required this.now,
    required this.photoUrl,
  });

  final String name;
  final DateTime now;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, $name',
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontWeight: FontWeight.w700,
                  fontSize: 30,
                  height: 1.15,
                  color: FjColors.navy900,
                ),
              ),
              const SizedBox(height: 6),
              const Row(
                children: [
                  Text(
                    'Walk with God today',
                    style: TextStyle(color: FjColors.gray500, fontSize: 14),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.auto_awesome, size: 14, color: FjColors.gold500),
                ],
              ),
            ],
          ),
        ),
        CircleAvatar(
          radius: 26,
          backgroundColor: FjColors.gold300,
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
          child: photoUrl == null
              ? const Icon(Icons.person, color: Colors.white, size: 28)
              : null,
        ),
      ],
    );
  }
}

class _VerseOfDayCard extends ConsumerWidget {
  const _VerseOfDayCard({required this.now});
  final DateTime now;

  static int _dayOfYear(DateTime d) => d.difference(DateTime(d.year)).inDays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pick = _verseOfDay[_dayOfYear(now) % _verseOfDay.length];
    final chapter = ref.watch(
      bibleChapterProvider('KJV', pick.osis, pick.chapter),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(FjRadius.cardLg),
      onTap: () => context.go('/bible/KJV/${pick.osis}/${pick.chapter}'),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFBF4E8), Color(0xFFF1E2C0)],
          ),
          borderRadius: BorderRadius.circular(FjRadius.cardLg),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC8962F).withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: FjSpacing.lg,
          vertical: FjSpacing.xxl,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const _VerseIllustration(),
            const SizedBox(width: FjSpacing.lg),
            Expanded(
              child: chapter.when(
                loading: () => const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => _VerseBody(
                  reference: '${pick.osis} ${pick.chapter}:${pick.verse}',
                  text: 'Could not load verse. Pull down to refresh.',
                  onSave: null,
                  onReflect: null,
                ),
                data: (c) {
                  final v = c.verses.firstWhere(
                    (x) => x.number == pick.verse,
                    orElse: () => c.verses.first,
                  );
                  return _VerseBody(
                    reference: '${c.bookName} ${c.chapter}:${v.number}',
                    text: v.text,
                    onSave: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Verse saved — coming soon.')),
                    ),
                    onReflect: () => context.go('/journal/new'),
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

/// Stylized "Bible + cross" illustration built from Flutter primitives.
/// Drop in a real PNG/SVG at `assets/illustrations/bible.png` and swap this
/// for an `Image.asset(...)` when you have artwork.
class _VerseIllustration extends StatelessWidget {
  const _VerseIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft halo behind the cross
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFFF5D6).withValues(alpha: 0.95),
                  const Color(0xFFFFF5D6).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          const Positioned(
            top: 0,
            child: Icon(
              Icons.add, // serves as a simple cross silhouette
              size: 32,
              color: Color(0xFFC8962F),
            ),
          ),
          const Positioned(
            bottom: 0,
            child: Icon(
              Icons.menu_book,
              size: 60,
              color: Color(0xFF8C6B2E),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerseBody extends StatelessWidget {
  const _VerseBody({
    required this.reference,
    required this.text,
    required this.onSave,
    required this.onReflect,
  });

  final String reference;
  final String text;
  final VoidCallback? onSave;
  final VoidCallback? onReflect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Dash(),
            SizedBox(width: 8),
            Text(
              'Verse of the Day',
              style: TextStyle(
                color: FjColors.gold500,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(width: 8),
            _Dash(),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          reference,
          style: const TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: FjColors.navy900,
          ),
        ),
        const SizedBox(height: 6),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Dash(width: 14),
            SizedBox(width: 4),
            Icon(Icons.star, size: 8, color: FjColors.gold500),
            SizedBox(width: 4),
            _Dash(width: 14),
          ],
        ),
        const SizedBox(height: FjSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '"$text"',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontWeight: FontWeight.w600,
              fontSize: 19,
              height: 1.35,
              color: FjColors.navy900,
            ),
          ),
        ),
        const SizedBox(height: FjSpacing.lg),
        const Divider(height: 1, color: Color(0x33C8962F)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.bookmark_outline,
                    size: 18, color: FjColors.navy700),
                label: const Text(
                  'Save',
                  style: TextStyle(
                    color: FjColors.navy700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Container(width: 1, height: 20, color: const Color(0x33C8962F)),
            Expanded(
              child: TextButton.icon(
                onPressed: onReflect,
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: FjColors.navy700),
                label: const Text(
                  'Reflect',
                  style: TextStyle(
                    color: FjColors.navy700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Dash extends StatelessWidget {
  const _Dash({this.width = 24});
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 1,
      color: const Color(0x66C8962F),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.menu_book_outlined,
                title: 'Bible',
                subtitle: 'Read the Word',
                onTap: () => context.go('/bible'),
              ),
            ),
            const SizedBox(width: FjSpacing.md),
            Expanded(
              child: _ActionCard(
                icon: Icons.book_outlined,
                title: 'Journal',
                subtitle: 'Write & Reflect',
                onTap: () => context.go('/journal'),
              ),
            ),
          ],
        ),
        const SizedBox(height: FjSpacing.md),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.volunteer_activism_outlined,
                title: 'Prayers',
                subtitle: 'Lift your heart',
                onTap: () => context.go('/prayer'),
              ),
            ),
            const SizedBox(width: FjSpacing.md),
            Expanded(
              child: _ActionCard(
                icon: Icons.search,
                title: 'Search',
                subtitle: 'Find in Scripture',
                onTap: () => context.go('/bible/search'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FjColors.surface0,
      borderRadius: BorderRadius.circular(FjRadius.card),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(FjRadius.card),
        onTap: onTap,
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
          padding: const EdgeInsets.symmetric(
            horizontal: FjSpacing.lg,
            vertical: FjSpacing.lg,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: FjColors.gold500.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: FjColors.gold500, size: 24),
              ),
              const SizedBox(width: FjSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: FjColors.navy900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: FjColors.gray500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentReflectionsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Recent Reflections',
            style: TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: FjColors.navy900,
            ),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go('/journal'),
          child: const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            child: Row(
              children: [
                Text(
                  'View all',
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

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.entry, required this.index});
  final JournalEntry entry;
  final int index;

  /// Four palette presets rotated by index, so each card gets a slightly
  /// different gradient placeholder. Drop in a real Image.asset later.
  static const List<List<Color>> _palettes = [
    [Color(0xFFF8E2C2), Color(0xFFE7C28A)], // sunrise
    [Color(0xFFE3DBC2), Color(0xFFB9B07E)], // sage / olive
    [Color(0xFFD9D6CC), Color(0xFFA9A38F)], // stone
    [Color(0xFFEED8B6), Color(0xFFC8962F)], // gold
  ];

  @override
  Widget build(BuildContext context) {
    final palette = _palettes[index % _palettes.length];
    final firstCategory =
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
                  color: FjColors.navy900.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                _Thumbnail(palette: palette),
                const SizedBox(width: FjSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MetaLine(date: entry.createdAt, tag: firstCategory),
                      const SizedBox(height: 6),
                      Text(
                        entry.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          height: 1.35,
                          color: FjColors.navy900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: FjColors.gold500.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward,
                      size: 18, color: FjColors.gold500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.palette});
  final List<Color> palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 84,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 8,
            top: 8,
            child: Icon(
              Icons.wb_sunny_outlined,
              color: Colors.white.withValues(alpha: 0.7),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.date, required this.tag});
  final DateTime? date;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (date != null) _formatDate(date!),
      if (tag != null) _humanize(tag!),
    ];
    return Text(
      parts.join(' · '),
      style: const TextStyle(
        color: FjColors.gray500,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  static String _humanize(String slug) =>
      slug.isEmpty ? slug : slug[0].toUpperCase() + slug.substring(1);

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

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(FjSpacing.xxl),
      decoration: BoxDecoration(
        color: FjColors.surface0,
        borderRadius: BorderRadius.circular(FjRadius.card),
        boxShadow: [
          BoxShadow(
            color: FjColors.navy900.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.edit_outlined, size: 36, color: FjColors.gray300),
          SizedBox(height: FjSpacing.sm),
          Text(
            'No reflections yet.',
            style: TextStyle(
              color: FjColors.navy900,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tap "Journal" above to write your first.',
            style: TextStyle(color: FjColors.gray500, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
