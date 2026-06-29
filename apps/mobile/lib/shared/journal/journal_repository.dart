import 'package:cloud_firestore/cloud_firestore.dart';

import 'journal_entry.dart';

/// CRUD for journal entries stored at `users/{uid}/journal_entries/{id}`.
class JournalRepository {
  JournalRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _entries(String uid) =>
      _firestore.collection('users').doc(uid).collection('journal_entries');

  Stream<List<JournalEntry>> watchEntries(String uid) => _entries(uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((q) => q.docs.map(JournalEntry.fromSnapshot).toList());

  Future<JournalEntry?> getEntry(String uid, String id) async {
    final snap = await _entries(uid).doc(id).get();
    return snap.exists ? JournalEntry.fromSnapshot(snap) : null;
  }

  /// Create a new entry. `type` defaults to text; pass [verseRef] +
  /// [verseReference] + [verseText] to attach a pinned verse to a text
  /// reflection, or use [createVerseEntry] for verse-only entries.
  Future<String> createEntry(
    String uid, {
    required String text,
    JournalEntryType type = JournalEntryType.text,
    List<String> categories = const [],
    String? verseRef,
    String? verseReference,
    String? verseText,
  }) async {
    final now = FieldValue.serverTimestamp();
    final ref = await _entries(uid).add({
      'type': type.slug,
      'text': text,
      'categories': categories,
      if (verseRef != null) 'verseRef': verseRef,
      if (verseReference != null) 'verseReference': verseReference,
      if (verseText != null) 'verseText': verseText,
      'createdAt': now,
      'updatedAt': now,
    });
    return ref.id;
  }

  /// Save a Bible verse as a journal entry (no user body).
  Future<String> createVerseEntry(
    String uid, {
    required String verseRef,
    required String verseReference,
    required String verseText,
    List<String> categories = const [],
  }) =>
      createEntry(
        uid,
        text: '',
        type: JournalEntryType.verse,
        verseRef: verseRef,
        verseReference: verseReference,
        verseText: verseText,
        categories: categories,
      );

  Future<void> updateEntry(
    String uid,
    String id, {
    String? text,
    List<String>? categories,
  }) =>
      _entries(uid).doc(id).update({
        if (text != null) 'text': text,
        if (categories != null) 'categories': categories,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> deleteEntry(String uid, String id) =>
      _entries(uid).doc(id).delete();
}
