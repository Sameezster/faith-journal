library fj_models;

/// Cross-feature, cross-platform data models (Freezed in production).
/// Shared so the Phase-2 read-only web portal reuses the same shapes.

enum PrayerStatus { active, inProgress, answered }

enum ReflectionType { text, voice }

class SavedVerse {
  const SavedVerse({
    required this.id,
    required this.reference,
    required this.translation,
    required this.text,
    required this.categories,
    required this.createdAt,
  });
  final String id;
  final String reference;
  final String translation;
  final String text;
  final List<String> categories;
  final DateTime createdAt;
}
