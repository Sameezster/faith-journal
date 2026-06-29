import 'package:cloud_firestore/cloud_firestore.dart';

/// What kind of entry this is. Rendering and editor flow differ per type.
enum JournalEntryType {
  /// Free-form written reflection. May optionally be linked to a verse.
  text,

  /// A pinned Bible verse (no user-authored body required).
  verse,

  /// Audio reflection (waveform stored as `voiceUrl` in Firebase Storage).
  voice,
}

extension JournalEntryTypeX on JournalEntryType {
  String get slug => switch (this) {
        JournalEntryType.text => 'text',
        JournalEntryType.verse => 'verse',
        JournalEntryType.voice => 'voice',
      };

  static JournalEntryType fromSlug(String? s) => switch (s) {
        'verse' => JournalEntryType.verse,
        'voice' => JournalEntryType.voice,
        _ => JournalEntryType.text,
      };
}

/// A journal entry stored at `users/{uid}/journal_entries/{id}`.
class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.type,
    required this.text,
    required this.categories,
    this.verseRef,
    this.verseReference,
    this.verseText,
    this.voiceUrl,
    this.voiceDurationSeconds,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final JournalEntryType type;

  /// The user-authored text. Empty for `verse` and `voice` entries.
  final String text;
  final List<String> categories;

  /// Canonical pinned verse, e.g. `KJV:John:3:16`.
  /// Set when the user "saves" a verse or attaches one to a reflection.
  final String? verseRef;

  /// Human-readable verse reference for display, e.g. `John 3:16`.
  final String? verseReference;

  /// Cached verse text so the timeline doesn't need to refetch.
  final String? verseText;

  /// Firebase Storage URL of the audio file (voice entries only).
  final String? voiceUrl;

  /// Duration of the audio in whole seconds (voice entries only).
  final int? voiceDurationSeconds;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory JournalEntry.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final d = snap.data() ?? const <String, dynamic>{};
    return JournalEntry(
      id: snap.id,
      type: JournalEntryTypeX.fromSlug(d['type'] as String?),
      text: d['text'] as String? ?? '',
      categories: (d['categories'] as List?)?.cast<String>() ?? const [],
      verseRef: d['verseRef'] as String?,
      verseReference: d['verseReference'] as String?,
      verseText: d['verseText'] as String?,
      voiceUrl: d['voiceUrl'] as String?,
      voiceDurationSeconds: (d['voiceDurationSeconds'] as num?)?.toInt(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
