import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/journal/journal_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Suggested tags shown in the verse action sheet. We can replace this with
/// AI-driven suggestions later — kept static so the sheet works offline.
const List<({String slug, String label, IconData icon})> _suggestedTags = [
  (slug: 'faith', label: 'Faith', icon: LucideIcons.leaf),
  (slug: 'hope', label: 'Hope', icon: LucideIcons.anchor),
  (slug: 'strength', label: 'Strength', icon: LucideIcons.shield),
  (slug: 'wisdom', label: 'Wisdom', icon: LucideIcons.bookOpen),
];

/// Bottom sheet shown when a verse is tapped. Lets the user save, highlight,
/// tag, add a reflection, or share. Save / Add Reflection / Share are wired;
/// Highlight and Add Tag are placeholders for now.
Future<void> showVerseActionSheet(
  BuildContext context, {
  required String translation,
  required String book,
  required int chapter,
  required int verseNumber,
  required String verseReference,
  required String verseText,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _VerseActionSheet(
      translation: translation,
      book: book,
      chapter: chapter,
      verseNumber: verseNumber,
      verseReference: verseReference,
      verseText: verseText,
    ),
  );
}

class _VerseActionSheet extends ConsumerStatefulWidget {
  const _VerseActionSheet({
    required this.translation,
    required this.book,
    required this.chapter,
    required this.verseNumber,
    required this.verseReference,
    required this.verseText,
  });

  final String translation;
  final String book;
  final int chapter;
  final int verseNumber;
  final String verseReference;
  final String verseText;

  @override
  ConsumerState<_VerseActionSheet> createState() => _VerseActionSheetState();
}

class _VerseActionSheetState extends ConsumerState<_VerseActionSheet> {
  final Set<String> _selectedTags = <String>{};
  bool _highlighted = false;
  bool _saving = false;

  String get _verseRef =>
      '${widget.translation}:${widget.book}:${widget.chapter}:${widget.verseNumber}';

  Future<void> _save() async {
    if (_saving) return;
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(journalRepositoryProvider).createVerseEntry(
            user.uid,
            verseRef: _verseRef,
            verseReference: widget.verseReference,
            verseText: widget.verseText,
            categories: _selectedTags.toList(),
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved ${widget.verseReference} to journal.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  void _addReflection() {
    Navigator.pop(context);
    context.go('/journal/new?ref=$_verseRef');
  }

  Future<void> _share() async {
    final shareText =
        '"${widget.verseText}"\n— ${widget.verseReference} (${widget.translation})';
    await Clipboard.setData(ClipboardData(text: shareText));
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grab handle.
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.placeholder.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Verse preview.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.champagne.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(AppIcons.bible,
                      size: 23, color: AppColors.gold),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.verseReference,
                          style: AppTextStyles.verseReference),
                      const SizedBox(height: 6),
                      Text(
                        widget.verseText,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.charcoal.withValues(alpha: 0.85),
                          height: 1.45,
                          fontSize: 14.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 20),

            // Actions.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SheetAction(
                  icon: AppIcons.bookmark,
                  label: 'Save',
                  busy: _saving,
                  onTap: _save,
                ),
                _SheetAction(
                  icon: LucideIcons.penLine,
                  label: 'Highlight',
                  active: _highlighted,
                  onTap: () => setState(() => _highlighted = !_highlighted),
                ),
                _SheetAction(
                  icon: AppIcons.tag,
                  label: 'Add Tag',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tap a tag below, then Save.')),
                  ),
                ),
                _SheetAction(
                  icon: AppIcons.noteLines,
                  label: 'Add Reflection',
                  onTap: _addReflection,
                ),
                _SheetAction(
                  icon: AppIcons.share,
                  label: 'Share',
                  onTap: _share,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 18),

            // Suggested tags.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Suggested Tags',
                    style: AppTextStyles.h2.copyWith(fontSize: 17)),
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Tag management — coming soon.')),
                  ),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Text('Manage Tags',
                          style: AppTextStyles.body.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      const Icon(AppIcons.forward,
                          size: 16, color: AppColors.gold),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final t in _suggestedTags)
                  _TagPill(
                    icon: t.icon,
                    label: t.label,
                    active: _selectedTags.contains(t.slug),
                    onTap: () => setState(() {
                      if (!_selectedTags.remove(t.slug)) {
                        _selectedTags.add(t.slug);
                      }
                    }),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final iconColor = active ? AppColors.gold : AppColors.navy;
    // Icon-only action — each gets an equal column with a soft tinted chip.
    return Expanded(
      child: Center(
        child: InkWell(
          onTap: busy ? null : onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.gold.withValues(alpha: 0.14)
                  : AppColors.champagne.withValues(alpha: 0.32),
              borderRadius: BorderRadius.circular(15),
              border: active
                  ? Border.all(color: AppColors.gold.withValues(alpha: 0.4))
                  : null,
            ),
            child: busy
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Icon(icon, size: 23, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active
              ? AppColors.gold.withValues(alpha: 0.14)
              : AppColors.sage.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active
                ? AppColors.gold.withValues(alpha: 0.5)
                : AppColors.sage.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15, color: active ? AppColors.gold : AppColors.sage),
            const SizedBox(width: 7),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                fontSize: 13.5,
                color: active ? AppColors.gold : AppColors.navy,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
