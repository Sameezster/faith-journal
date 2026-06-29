import 'package:cloud_firestore/cloud_firestore.dart';

/// Lifecycle of a prayer request.
enum PrayerStatus { active, waiting, answered }

extension PrayerStatusX on PrayerStatus {
  String get slug => switch (this) {
        PrayerStatus.active => 'active',
        PrayerStatus.waiting => 'waiting',
        PrayerStatus.answered => 'answered',
      };

  String get label => switch (this) {
        PrayerStatus.active => 'Active',
        PrayerStatus.waiting => 'Waiting',
        PrayerStatus.answered => 'Answered',
      };

  static PrayerStatus fromSlug(String? s) => switch (s) {
        'waiting' => PrayerStatus.waiting,
        'answered' => PrayerStatus.answered,
        _ => PrayerStatus.active,
      };
}

/// A single prayer request, stored at `users/{uid}/prayer_requests/{id}`.
///
/// `title` and `description` are user-authored; `category` is one of the
/// slugs from [kPrayerCategories]; `date` is user-selected (e.g., the day
/// the prayer concerns) and is distinct from `createdAt` (system-set).
class PrayerRequest {
  const PrayerRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.category,
    this.date,
    this.createdAt,
    this.updatedAt,
    this.answeredAt,
  });

  final String id;
  final String title;
  final String description;
  final PrayerStatus status;
  final String? category;
  final DateTime? date;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? answeredAt;

  /// Display date — user-set `date` if present, else falls back to `createdAt`.
  DateTime? get displayDate => date ?? createdAt;

  factory PrayerRequest.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final d = snap.data() ?? const <String, dynamic>{};
    // Backwards-compat: older docs stored the body under `text`.
    final desc = d['description'] as String? ?? d['text'] as String? ?? '';
    return PrayerRequest(
      id: snap.id,
      title: d['title'] as String? ?? _deriveTitle(desc),
      description: desc,
      status: PrayerStatusX.fromSlug(d['status'] as String?),
      category: d['category'] as String?,
      date: (d['date'] as Timestamp?)?.toDate(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      answeredAt: (d['answeredAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Generates a fallback title from the description (first ~40 chars).
  /// Used only when reading legacy docs that lack an explicit title.
  static String _deriveTitle(String description) {
    final trimmed = description.trim();
    if (trimmed.isEmpty) return 'Untitled prayer';
    if (trimmed.length <= 40) return trimmed;
    return '${trimmed.substring(0, 40).trimRight()}…';
  }
}
