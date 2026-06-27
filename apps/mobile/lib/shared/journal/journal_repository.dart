import 'package:cloud_firestore/cloud_firestore.dart';

import 'journal_entry.dart';

/// CRUD for journal entries stored at `users/{uid}/journal_entries/{id}`.
///
/// All paths are scoped under `users/{uid}`, so Firestore security rules
/// automatically deny cross-user access.
class JournalRepository {
  JournalRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _entries(String uid) =>
      _firestore.collection('users').doc(uid).collection('journal_entries');

  /// Live stream of all entries, newest first.
  Stream<List<JournalEntry>> watchEntries(String uid) => _entries(uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((q) => q.docs.map(JournalEntry.fromSnapshot).toList());

  /// One-shot read of a single entry.
  Future<JournalEntry?> getEntry(String uid, String id) async {
    final snap = await _entries(uid).doc(id).get();
    return snap.exists ? JournalEntry.fromSnapshot(snap) : null;
  }

  /// Create a new entry. Returns the generated ID.
  Future<String> createEntry(
    String uid, {
    required String text,
    List<String> categories = const [],
  }) async {
    final now = FieldValue.serverTimestamp();
    final ref = await _entries(uid).add({
      'text': text,
      'categories': categories,
      'createdAt': now,
      'updatedAt': now,
    });
    return ref.id;
  }

  /// Patch an existing entry. Only the provided fields are written;
  /// `updatedAt` is always refreshed.
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
