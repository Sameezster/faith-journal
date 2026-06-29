import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// A categorization tag a prayer request can carry.
class PrayerCategoryDef {
  const PrayerCategoryDef({
    required this.slug,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String slug;
  final String label;
  final IconData icon;
  final Color color;
}

/// All available categories. Update this list to add or remove tags.
const List<PrayerCategoryDef> kPrayerCategories = [
  PrayerCategoryDef(
    slug: 'family',
    label: 'Family',
    icon: Icons.favorite_outline,
    color: FjColors.sage500,
  ),
  PrayerCategoryDef(
    slug: 'friends',
    label: 'Friends',
    icon: Icons.favorite,
    color: FjColors.gold500,
  ),
  PrayerCategoryDef(
    slug: 'work',
    label: 'Work',
    icon: Icons.work_outline,
    color: FjColors.gold500,
  ),
  PrayerCategoryDef(
    slug: 'health',
    label: 'Health',
    icon: Icons.local_hospital_outlined,
    color: FjColors.sage500,
  ),
  PrayerCategoryDef(
    slug: 'personal',
    label: 'Personal',
    icon: Icons.person_outline,
    color: FjColors.sage500,
  ),
  PrayerCategoryDef(
    slug: 'church',
    label: 'Church',
    icon: Icons.church_outlined,
    color: FjColors.gold500,
  ),
  PrayerCategoryDef(
    slug: 'other',
    label: 'Other',
    icon: Icons.label_outline,
    color: FjColors.gray500,
  ),
];

PrayerCategoryDef? findPrayerCategory(String? slug) {
  if (slug == null) return null;
  for (final c in kPrayerCategories) {
    if (c.slug == slug) return c;
  }
  return null;
}
