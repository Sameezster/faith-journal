import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/bible_provider/bible_providers.dart';
import '../../../shared/journal/journal_providers.dart';
import '../../auth/presentation/providers/auth_providers.dart';

/// Available tag chips shown below the reflection text field. We can later
/// swap these for AI-driven suggestions; static for now so the editor works
/// offline.
const List<({String slug, String label, IconData icon, Color color})>
    _reflectionTags = [
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
    slug: 'peace',
    label: 'Peace',
    icon: Icons.spa_outlined,
    color: FjColors.sage500,
  ),
  (
    slug: 'strength',
    label: 'Strength',
    icon: Icons.shield_outlined,
    color: FjColors.sage500,
  ),
  (
    slug: 'love',
    label: 'Love',
    icon: Icons.favorite_outline,
    color: FjColors.gold500,
  ),
  (
    slug: 'wisdom',
    label: 'Wisdom',
    icon: Icons.lightbulb_outline,
    color: FjColors.gold500,
  ),
];

const int _maxChars = 1000;

class JournalEditorScreen extends ConsumerStatefulWidget {
  const JournalEditorScreen({super.key, this.entryId, this.pinnedVerseRef});

  final String? entryId;
  final String? pinnedVerseRef;

  @override
  ConsumerState<JournalEditorScreen> createState() =>
      _JournalEditorScreenState();
}

class _JournalEditorScreenState extends ConsumerState<JournalEditorScreen> {
  final _controller = TextEditingController();
  bool _busy = false;
  bool _loaded = false;
  final Set<String> _selectedTags = <String>{};
  ({String reference, String text})? _pinnedVerse;

  bool get _isEditing => widget.entryId != null;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    if (_isEditing) {
      _loadExisting();
    } else {
      _loaded = true;
      if (widget.pinnedVerseRef != null) _loadPinnedVerse();
    }
  }

  Future<void> _loadPinnedVerse() async {
    final parts = widget.pinnedVerseRef!.split(':');
    if (parts.length != 4) return;
    final translation = parts[0];
    final book = parts[1];
    final chapter = int.tryParse(parts[2]);
    final verse = int.tryParse(parts[3]);
    if (chapter == null || verse == null) return;
    try {
      final c = await ref
          .read(bibleRepositoryProvider)
          .getChapter(translation, book, chapter);
      final v = c.verses.firstWhere(
        (x) => x.number == verse,
        orElse: () => c.verses.first,
      );
      if (!mounted) return;
      setState(() {
        _pinnedVerse = (
          reference: '${c.bookName} ${c.chapter}:${v.number}',
          text: v.text,
        );
      });
    } catch (_) {
      // Silent — pinned card just won't render.
    }
  }

  Future<void> _loadExisting() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final entry = await ref
        .read(journalRepositoryProvider)
        .getEntry(user.uid, widget.entryId!);
    if (!mounted) return;
    if (entry != null) {
      _controller.text = entry.text;
      _selectedTags.addAll(entry.categories);
      if (entry.verseReference != null && entry.verseText != null) {
        _pinnedVerse = (
          reference: entry.verseReference!,
          text: entry.verseText!,
        );
      }
    }
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write your reflection first.')),
      );
      return;
    }
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() => _busy = true);
    try {
      final repo = ref.read(journalRepositoryProvider);
      final categories = _selectedTags.toList();
      if (_isEditing) {
        await repo.updateEntry(
          user.uid,
          widget.entryId!,
          text: text,
          categories: categories,
        );
      } else {
        await repo.createEntry(
          user.uid,
          text: text,
          categories: categories,
          verseRef: widget.pinnedVerseRef,
          verseReference: _pinnedVerse?.reference,
          verseText: _pinnedVerse?.text,
        );
      }
      if (!mounted) return;
      context.go('/journal');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete() async {
    if (!_isEditing) return;
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(journalRepositoryProvider)
          .deleteEntry(user.uid, widget.entryId!);
      if (!mounted) return;
      context.go('/journal');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _pinnedVerse != null || widget.pinnedVerseRef != null
        ? 'Add Reflection'
        : _isEditing
            ? 'Edit Reflection'
            : 'New Reflection';

    return Scaffold(
      backgroundColor: FjColors.cream50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: FjColors.gold500),
          onPressed: () => context.go('/journal'),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: FjColors.navy900,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: FjColors.gold500),
              onPressed: _busy ? null : _confirmDelete,
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        FjSpacing.gutter,
                        FjSpacing.sm,
                        FjSpacing.gutter,
                        FjSpacing.lg,
                      ),
                      children: [
                        if (_pinnedVerse != null) ...[
                          _PinnedVerseCard(
                            reference: _pinnedVerse!.reference,
                            text: _pinnedVerse!.text,
                          ),
                          const SizedBox(height: FjSpacing.xxl),
                        ],
                        const Text(
                          'Your Reflection',
                          style: TextStyle(
                            color: FjColors.navy900,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: FjSpacing.md),
                        _ReflectionField(
                          controller: _controller,
                          maxChars: _maxChars,
                        ),
                        const SizedBox(height: FjSpacing.xxl),
                        const Text(
                          'Add Tags (optional)',
                          style: TextStyle(
                            color: FjColors.navy900,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: FjSpacing.md),
                        _TagsRow(
                          selected: _selectedTags,
                          onToggle: (slug) {
                            setState(() {
                              if (_selectedTags.contains(slug)) {
                                _selectedTags.remove(slug);
                              } else {
                                _selectedTags.add(slug);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      FjSpacing.gutter,
                      0,
                      FjSpacing.gutter,
                      FjSpacing.md,
                    ),
                    child: _SaveButton(busy: _busy, onTap: _save),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Pinned verse card shown at the top of the reflection editor.
class _PinnedVerseCard extends StatelessWidget {
  const _PinnedVerseCard({required this.reference, required this.text});

  final String reference;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(FjSpacing.lg),
      decoration: BoxDecoration(
        color: FjColors.surface0,
        borderRadius: BorderRadius.circular(FjRadius.card),
        boxShadow: [
          BoxShadow(
            color: FjColors.navy900.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: FjColors.gold500.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child:
                const Icon(Icons.menu_book, color: FjColors.gold500, size: 22),
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
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    color: FjColors.navy900,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReflectionField extends StatelessWidget {
  const _ReflectionField({required this.controller, required this.maxChars});

  final TextEditingController controller;
  final int maxChars;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FjColors.surface0.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(FjRadius.input),
        border: Border.all(color: FjColors.gray300),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          FjSpacing.lg,
          FjSpacing.md,
          FjSpacing.lg,
          FjSpacing.sm,
        ),
        child: Column(
          children: [
            TextField(
              controller: controller,
              maxLines: 8,
              minLines: 8,
              maxLength: maxChars,
              maxLengthEnforcement:
                  MaxLengthEnforcement.truncateAfterCompositionEnds,
              style: const TextStyle(
                color: FjColors.navy900,
                fontSize: 15,
                height: 1.55,
              ),
              decoration: const InputDecoration(
                hintText: 'Write what God spoke to you…',
                hintStyle: TextStyle(color: FjColors.gray500),
                border: InputBorder.none,
                filled: false,
                counterText: '',
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${controller.text.characters.length}/$maxChars',
                style: const TextStyle(
                  color: FjColors.gray500,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagsRow extends StatelessWidget {
  const _TagsRow({required this.selected, required this.onToggle});

  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _reflectionTags.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final t = _reflectionTags[i];
          final isSelected = selected.contains(t.slug);
          return _TagChip(
            label: t.label,
            icon: t.icon,
            color: t.color,
            selected: isSelected,
            onTap: () => onToggle(t.slug),
          );
        },
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
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.18)
              : color.withValues(alpha: 0.08),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.25),
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: busy ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: FjColors.gold500,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FjRadius.button),
        ),
      ),
      child: busy
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wb_sunny_outlined, size: 20),
                SizedBox(width: 8),
                Text(
                  'Save Reflection',
                  style: TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
    );
  }
}
