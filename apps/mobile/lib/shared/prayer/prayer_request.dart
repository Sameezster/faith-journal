import 'package:cloud_firestore/cloud_firestore.dart';

/// Lifecycle of a prayer request.
enum PrayerStatus { active, waiting, answered }

extension PrayerStatusX on PrayerStatus {
  String get slug => switch (this) {
        PrayerStatus.active => 'active',
        PrayerStatus.waiting => 'waiting',
        PrayerStatus.answered => 'answered',
      };

  /// Label shown in the UI. `waiting` displays as "In Progress" to match
  /// the design — the underlying status slug is still `waiting` so legacy
  /// docs continue to work.
  String get label => switch (this) {
        PrayerStatus.active => 'Active',
        PrayerStatus.waiting => 'In Progress',
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
    this.testimony,
    this.verseRef,
    this.verseReference,
    this.voiceUrl,
    this.voiceDurationSeconds,
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

  /// What the user believes God is doing or has promised — shown as a
  /// "Testimony" section on the detail screen.
  final String? testimony;

  /// Canonical pinned verse, e.g. `KJV:Isa:53:5`.
  final String? verseRef;

  /// Human-readable verse reference for display, e.g. `Isaiah 53:5`.
  final String? verseReference;

  /// Firebase Storage URL of the attached voice note (if any).
  final String? voiceUrl;
  final int? voiceDurationSeconds;

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
      testimony: d['testimony'] as String?,
      verseRef: d['verseRef'] as String?,
      verseReference: d['verseReference'] as String?,
      voiceUrl: d['voiceUrl'] as String?,
      voiceDurationSeconds: (d['voiceDurationSeconds'] as num?)?.toInt(),
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
