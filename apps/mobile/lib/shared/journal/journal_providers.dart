import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import 'journal_entry.dart';
import 'journal_repository.dart';

part 'journal_providers.g.dart';

@riverpod
JournalRepository journalRepository(JournalRepositoryRef ref) =>
    JournalRepository(FirebaseFirestore.instance);

/// Live list of the signed-in user's entries (newest first).
/// Emits an empty list when signed out.
@riverpod
Stream<List<JournalEntry>> journalEntries(JournalEntriesRef ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const []);
  return ref.watch(journalRepositoryProvider).watchEntries(user.uid);
}

/// Live single entry by ID. Null while loading or if not found.
@riverpod
Stream<JournalEntry?> journalEntry(JournalEntryRef ref, String id) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('journal_entries')
      .doc(id)
      .snapshots()
      .map((s) => s.exists ? JournalEntry.fromSnapshot(s) : null);
}
