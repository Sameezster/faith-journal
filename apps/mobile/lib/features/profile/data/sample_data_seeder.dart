import '../../../shared/journal/journal_entry.dart';
import '../../../shared/journal/journal_repository.dart';
import '../../../shared/prayer/prayer_repository.dart';
import '../../../shared/prayer/prayer_request.dart';

/// Writes a handful of representative prayers and journal entries to Firestore
/// for the signed-in user. Safe to call multiple times — each call simply
/// appends new entries (it does not deduplicate).
class SampleDataSeeder {
  SampleDataSeeder(this._prayers, this._journal);

  final PrayerRepository _prayers;
  final JournalRepository _journal;

  Future<({int prayers, int entries})> seed(String uid) async {
    var prayerCount = 0;
    for (final p in _samplePrayers) {
      await _prayers.createRequest(
        uid,
        title: p.title,
        description: p.description,
        status: p.status,
        category: p.category,
        date: p.date,
      );
      prayerCount++;
    }
    var entryCount = 0;
    for (final e in _sampleEntries) {
      await _journal.createEntry(
        uid,
        text: e.text,
        type: e.type,
        categories: e.categories,
        verseRef: e.verseRef,
        verseReference: e.verseReference,
        verseText: e.verseText,
      );
      entryCount++;
    }
    return (prayers: prayerCount, entries: entryCount);
  }
}

class _SamplePrayer {
  // Not `const` because `date` is derived from `DateTime.now()`.
  _SamplePrayer({
    required this.title,
    required this.description,
    required this.status,
    required this.category,
    required this.date,
  });
  final String title;
  final String description;
  final PrayerStatus status;
  final String category;
  final DateTime date;
}

class _SampleEntry {
  const _SampleEntry({
    required this.type,
    required this.text,
    required this.categories,
    this.verseRef,
    this.verseReference,
    this.verseText,
  });
  final JournalEntryType type;
  final String text;
  final List<String> categories;
  final String? verseRef;
  final String? verseReference;
  final String? verseText;
}

final List<_SamplePrayer> _samplePrayers = [
  _SamplePrayer(
    title: "My Family's Health",
    description:
        "Praying for long life, protection, and complete health for my family.",
    status: PrayerStatus.active,
    category: 'family',
    date: DateTime.now().subtract(const Duration(days: 1)),
  ),
  _SamplePrayer(
    title: 'New Job Opportunity',
    description:
        'Praying for God to open the right doors and lead me to the right opportunity.',
    status: PrayerStatus.waiting,
    category: 'work',
    date: DateTime.now().subtract(const Duration(days: 3)),
  ),
  _SamplePrayer(
    title: 'Peace of Mind',
    description:
        'Praying for peace, less anxiety, and a stronger faith each day.',
    status: PrayerStatus.answered,
    category: 'personal',
    date: DateTime.now().subtract(const Duration(days: 5)),
  ),
  _SamplePrayer(
    title: "Friend's Healing",
    description: "Praying for my friend's surgery and complete recovery.",
    status: PrayerStatus.active,
    category: 'friends',
    date: DateTime.now().subtract(const Duration(days: 7)),
  ),
  _SamplePrayer(
    title: 'Our Church',
    description:
        "Praying for unity, growth, and God's vision to be fulfilled.",
    status: PrayerStatus.waiting,
    category: 'church',
    date: DateTime.now().subtract(const Duration(days: 9)),
  ),
];

final List<_SampleEntry> _sampleEntries = [
  const _SampleEntry(
    type: JournalEntryType.verse,
    text: '',
    categories: ['faith', 'hope', 'strength'],
    verseRef: 'KJV:John:3:16',
    verseReference: 'John 3:16',
    verseText:
        'For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.',
  ),
  const _SampleEntry(
    type: JournalEntryType.text,
    text:
        "Today I was reminded that I don't have to carry everything on my own. God is with me in every season, and His strength is enough for me. I choose to trust Him more each day.",
    categories: ['faith'],
  ),
  const _SampleEntry(
    type: JournalEntryType.verse,
    text: '',
    categories: ['strength', 'faith'],
    verseRef: 'KJV:Psa:23:1',
    verseReference: 'Psalms 23:1',
    verseText: 'The LORD is my shepherd; I shall not want.',
  ),
  const _SampleEntry(
    type: JournalEntryType.text,
    text:
        "I'm learning to give my worries to God in prayer. He cares about every detail of my life.",
    categories: ['hope', 'peace'],
    verseRef: 'KJV:Phi:4:6',
    verseReference: 'Philippians 4:6',
    verseText:
        'Be careful for nothing; but in every thing by prayer and supplication with thanksgiving let your requests be made known unto God.',
  ),
  const _SampleEntry(
    type: JournalEntryType.verse,
    text: '',
    categories: ['hope', 'faith'],
    verseRef: 'KJV:Jer:29:11',
    verseReference: 'Jeremiah 29:11',
    verseText:
        'For I know the thoughts that I think toward you, saith the LORD, thoughts of peace, and not of evil, to give you an expected end.',
  ),
];
