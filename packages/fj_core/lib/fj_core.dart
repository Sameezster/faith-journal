library fj_core;

/// Shared constants, failures, and utilities used across the app and web portal.
class Failure {
  const Failure(this.code, this.message);
  final String code;
  final String message;
}

/// The 11-category AI taxonomy (kept in sync with the backend taxonomy).
const kCategories = <String>[
  'Strength', 'Faith', 'Hope', 'Wisdom', 'Prayer', 'Love',
  'Forgiveness', 'Healing', 'Peace', 'Gratitude', 'Encouragement',
];
