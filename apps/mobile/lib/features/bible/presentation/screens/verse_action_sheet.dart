import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/journal/journal_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Suggested tags shown in the verse action sheet. We can replace this with
/// AI-driven suggestions later — kept static so the sheet works offline.
const List<({String slug, String label, IconData icon, Color color})>
    _suggestedTags = [
  (
    slug: 'faith',
    label: 'Faith',
    icon: Icons.eco_outlined,
    color: FjColors.sage500,
  ),
  (
    slug: 'hope',
    label: 'Hope',
    icon: Icons.anchor,
    color: FjColors.gold500,
  ),
  (
    slug: 'strength',
    label: 'Strength',
    icon: Icons.shield_outlined,
    color: FjColors.sage500,
  ),
  (
    slug: 'wisdom',
    label: 'Wisdom',
    icon: Icons.lightbulb_outline,
    color: FjColors.gold500,
  ),
];

/// Bottom sheet shown when a verse is tapped. Lets the user save, highlight,
/// tag, add a reflection, or share. Save / Add Reflection / Share are wired;
/// Highlight and Add Tag are placeholders that show a snackbar for now.
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
    backgroundColor: FjColors.surface0,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(FjRadius.cardLg)),
    ),
    builder: (ctx) => _VerseActionSheet(
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          FjSpacing.gutter,
          FjSpacing.lg,
          FjSpacing.gutter,
          FjSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: FjColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: FjSpacing.lg),
            _VerseHeader(
              reference: widget.verseReference,
              text: widget.verseText,
            ),
            const SizedBox(height: FjSpacing.lg),
            const Divider(height: 1, color: FjColors.gray300),
            const SizedBox(height: FjSpacing.md),
            _ActionRow(
              actions: [
                _Action(
                  icon: Icons.bookmark_outline,
                  label: 'Save',
                  selected: false,
                  busy: _saving,
                  onTap: _save,
                ),
                _Action(
                  icon: Icons.edit_outlined,
                  label: 'Highlight',
                  selected: _highlighted,
                  busy: false,
                  onTap: () => setState(() => _highlighted = !_highlighted),
                ),
                _Action(
                  icon: Icons.local_offer_outlined,
                  label: 'Add Tag',
                  selected: false,
                  busy: false,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tap a tag below, then Save.'),
                    ),
                  ),
                ),
                _Action(
                  icon: Icons.description_outlined,
                  label: 'Add Reflection',
                  selected: false,
                  busy: false,
                  onTap: _addReflection,
                ),
                _Action(
                  icon: Icons.ios_share_outlined,
                  label: 'Share',
                  selected: false,
                  busy: false,
                  onTap: _share,
                ),
              ],
            ),
            const SizedBox(height: FjSpacing.lg),
            const Divider(height: 1, color: FjColors.gray300),
            const SizedBox(height: FjSpacing.md),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Suggested Tags',
                    style: TextStyle(
                      color: FjColors.navy900,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Tag management — coming soon.')),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Manage Tags',
                          style: TextStyle(
                            color: FjColors.gold500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            size: 18, color: FjColors.gold500),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: FjSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggestedTags.map((t) {
                final isSelected = _selectedTags.contains(t.slug);
                return _TagChip(
                  label: t.label,
                  icon: t.icon,
                  color: t.color,
                  selected: isSelected,
                  onTap: () => setState(() {
                    if (isSelected) {
                      _selectedTags.remove(t.slug);
                    } else {
                      _selectedTags.add(t.slug);
                    }
                  }),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerseHeader extends StatelessWidget {
  const _VerseHeader({required this.reference, required this.text});

  final String reference;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: FjColors.gold500.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.menu_book, color: FjColors.gold500, size: 22),
        ),
        const SizedBox(width: FjSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reference,
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: FjColors.navy900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: const TextStyle(
                  color: FjColors.navy700,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.actions});
  final List<_Action> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions,
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.selected,
    required this.busy,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? FjColors.gold500 : FjColors.navy700;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(icon, color: color, size: 26),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.18)
              : color.withValues(alpha: 0.08),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.25),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
