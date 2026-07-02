import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/sparkle_divider.dart';
import '../../../shared/bible_provider/bible_providers.dart';
import '../../../shared/journal/journal_entry.dart';
import '../../../shared/journal/journal_providers.dart';
import '../../auth/domain/auth_repository.dart';
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

/// Home dashboard — greeting, Verse of the Day, quick actions and recent
/// reflections. Designed to feel calm and spacious.
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
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(journalEntriesProvider);
            ref.invalidate(translationsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            children: [
              _Header(name: displayName, now: now, photoUrl: photoUrl),
              const SizedBox(height: 26),
              _VerseOfTheDayCard(now: now),
              const SizedBox(height: 30),
              const _QuickActionsGrid(),
              const SizedBox(height: 36),
              _RecentReflections(entries: entries),
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

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------
class _Header extends StatelessWidget {
  const _Header({
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
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, $name',
                style: AppTextStyles.h1.copyWith(fontSize: 28, height: 1.15),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'Walk with God today',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.warmGray, fontSize: 15),
                  ),
                  const SizedBox(width: 8),
                  const SparkleShape(size: 13, color: AppColors.gold),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.12),
                blurRadius: 10,
              ),
            ],
            image: DecorationImage(
              image: photoUrl != null
                  ? NetworkImage(photoUrl!)
                  : const AssetImage(AppAssets.profileAvatar) as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Verse of the Day
// ---------------------------------------------------------------------------
class _VerseOfTheDayCard extends ConsumerWidget {
  const _VerseOfTheDayCard({required this.now});
  final DateTime now;

  static int _dayOfYear(DateTime d) => d.difference(DateTime(d.year)).inDays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pick = _verseOfDay[_dayOfYear(now) % _verseOfDay.length];
    final chapter = ref.watch(
      bibleChapterProvider('KJV', pick.osis, pick.chapter),
    );

    return GestureDetector(
      onTap: () => context.go('/bible/KJV/${pick.osis}/${pick.chapter}'),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.12),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFBF5E8), Color(0xFFF2E7CC)],
              ),
            ),
            child: SizedBox(
              height: 240,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left illustration (~46%), dissolving gently into the card so
                  // the image and cream read as one seamless surface.
                  Expanded(
                    flex: 46,
                    child: ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Colors.white, Colors.white, Colors.transparent],
                        stops: [0, 0.45, 0.98],
                      ).createShader(rect),
                      blendMode: BlendMode.dstIn,
                      child: Image.asset(
                        AppAssets.homeVerse,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),
                  ),

                  // Right content.
                  Expanded(
                    flex: 54,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(2, 16, 16, 16),
                      child: chapter.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (e, _) => _VerseBody(
                          reference:
                              '${pick.osis} ${pick.chapter}:${pick.verse}',
                          text: 'Could not load verse. Pull down to refresh.',
                          onSave: null,
                          onReflect: null,
                        ),
                        data: (c) {
                          final v = c.verses.firstWhere(
                            (x) => x.number == pick.verse,
                            orElse: () => c.verses.first,
                          );
                          final reference =
                              '${c.bookName} ${c.chapter}:${v.number}';
                          final verseRef =
                              'KJV:${pick.osis}:${pick.chapter}:${v.number}';
                          return _VerseBody(
                            reference: reference,
                            text: v.text,
                            onSave: () => _saveVerseToJournal(
                              context,
                              ref,
                              verseRef: verseRef,
                              reference: reference,
                              text: v.text,
                            ),
                            onReflect: () =>
                                context.go('/journal/new?ref=$verseRef'),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The right-hand side of the Verse of the Day card: label, reference,
/// sparkle divider, the quote, and the Save / Reflect actions.
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
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _LabelRule('Verse of the Day'),
        const SizedBox(height: 12),
        Text(
          reference,
          textAlign: TextAlign.center,
          style: AppTextStyles.verseReference.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 8),
        const SparkleDivider(lineWidth: 22, sparkleSize: 11),
        const SizedBox(height: 12),

        // Quote — real verses vary in length, so cap the lines instead of the
        // mock's fixed two-line FittedBox.
        SizedBox(
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: -14,
                child: Text(
                  '“',
                  style: AppTextStyles.appTitle.copyWith(
                    fontSize: 42,
                    color: AppColors.gold,
                    height: 1,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.appTitle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        const Divider(height: 1, color: Color(0x22000000)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _VerseAction(icon: AppIcons.save, label: 'Save', onTap: onSave),
            Container(
              width: 1,
              height: 18,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: const Color(0x33000000),
            ),
            _VerseAction(
                icon: AppIcons.reflect, label: 'Reflect', onTap: onReflect),
          ],
        ),
      ],
    );
  }
}

/// Pins a verse to the user's journal as a `type=verse` entry.
Future<void> _saveVerseToJournal(
  BuildContext context,
  WidgetRef ref, {
  required String verseRef,
  required String reference,
  required String text,
}) async {
  final AppUser? user = ref.read(authStateProvider).value;
  if (user == null) return;
  try {
    await ref.read(journalRepositoryProvider).createVerseEntry(
          user.uid,
          verseRef: verseRef,
          verseReference: reference,
          verseText: text,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved $reference to your journal.')),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not save: $e')),
    );
  }
}

/// A small gold label flanked by short rules, e.g. "— Verse of the Day —".
class _LabelRule extends StatelessWidget {
  const _LabelRule(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    Widget rule() => Container(width: 16, height: 1, color: AppColors.gold);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        rule(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            text,
            style: AppTextStyles.label.copyWith(
              color: AppColors.gold,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        rule(),
      ],
    );
  }
}

class _VerseAction extends StatelessWidget {
  const _VerseAction({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.navy),
          const SizedBox(width: 7),
          Text(label,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.navy, fontSize: 15)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick actions (2 x 2)
// ---------------------------------------------------------------------------
class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                image: AppAssets.actionBible,
                title: 'Bible',
                subtitle: 'Read the Word',
                onTap: () => context.go('/bible'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _ActionCard(
                image: AppAssets.actionJournal,
                title: 'Journal',
                subtitle: 'Write & Reflect',
                onTap: () => context.go('/journal'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                image: AppAssets.actionPrayer,
                title: 'Prayers',
                subtitle: 'Lift your heart',
                onTap: () => context.go('/prayer'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _ActionCard(
                image: AppAssets.actionSearch,
                title: 'Search',
                subtitle: 'Find in Scripture',
                onTap: () => context.push('/search'),
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
    required this.image,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String image;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.asset(image, width: 42, height: 42),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.h2.copyWith(fontSize: 18)),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent Reflections
// ---------------------------------------------------------------------------
class _RecentReflections extends StatelessWidget {
  const _RecentReflections({required this.entries});

  final AsyncValue<List<JournalEntry>> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Reflections',
                style: AppTextStyles.h2.copyWith(fontSize: 22)),
            GestureDetector(
              onTap: () => context.go('/journal'),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Text(
                    'View all',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(AppIcons.forward,
                      size: 18, color: AppColors.gold),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        entries.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text(
            'Could not load entries.\n$e',
            style: AppTextStyles.body.copyWith(color: AppColors.warmGray),
          ),
          data: (list) => list.isEmpty
              ? const _EmptyRecent()
              : Column(
                  children: [
                    for (final (i, entry) in list.take(3).indexed) ...[
                      if (i > 0) const SizedBox(height: 16),
                      _ReflectionCard(entry: entry, index: i),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _ReflectionCard extends StatelessWidget {
  const _ReflectionCard({required this.entry, required this.index});

  final JournalEntry entry;
  final int index;

  /// The two design illustrations, rotated by position in the list.
  static const List<String> _images = [
    AppAssets.homeReflection1,
    AppAssets.homeReflection2,
  ];

  @override
  Widget build(BuildContext context) {
    final image = _images[index % _images.length];
    final date = entry.createdAt != null ? _formatDate(entry.createdAt!) : '';
    final reference = entry.verseReference ??
        (entry.categories.isNotEmpty ? _humanize(entry.categories.first) : '');

    return GestureDetector(
      onTap: () => context.go('/journal/${entry.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child:
                  Image.asset(image, width: 88, height: 84, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(date, style: AppTextStyles.caption),
                      if (reference.isNotEmpty) ...[
                        Text('  •  ', style: AppTextStyles.caption),
                        Flexible(
                          child: Text(
                            reference,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.sage),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.text,
                    style:
                        AppTextStyles.body.copyWith(fontSize: 14, height: 1.35),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(AppIcons.arrowRight,
                  size: 18, color: AppColors.gold),
            ),
          ],
        ),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(AppIcons.reflect, size: 36, color: AppColors.placeholder),
          const SizedBox(height: 10),
          Text(
            'No reflections yet.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Journal" above to write your first.',
            style: AppTextStyles.caption.copyWith(fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
