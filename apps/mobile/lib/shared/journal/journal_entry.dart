import 'package:cloud_firestore/cloud_firestore.dart';

/// A single journal entry, stored at `users/{uid}/journal_entries/{id}`.
class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.text,
    required this.categories,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String text;
  final List<String> categories;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory JournalEntry.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final d = snap.data() ?? const <String, dynamic>{};
    return JournalEntry(
      id: snap.id,
      text: d['text'] as String? ?? '',
      categories: (d['categories'] as List?)?.cast<String>() ?? const [],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  JournalEntry copyWith({
    String? text,
    List<String>? categories,
  }) =>
      JournalEntry(
        id: id,
        text: text ?? this.text,
        categories: categories ?? this.categories,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
