import 'package:fj_ui/fj_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/ai/ai_service.dart';
import '../../../shared/bible_provider/bible_providers.dart';
import '../../../shared/journal/journal_providers.dart';
import '../../auth/presentation/providers/auth_providers.dart';

/// Full-screen editor for creating or editing a journal entry.
/// Pass [entryId] to edit; null = create.
/// Pass [pinnedVerseRef] (format: `TRANSLATION:OSIS:CHAPTER:VERSE`) to
/// pre-attach a Bible verse to a new reflection.
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
  bool _suggesting = false;

  /// Cached verse info when [JournalEditorScreen.pinnedVerseRef] is set.
  /// Looks like `(reference: 'John 3:16', text: 'For God so loved…')`.
  ({String reference, String text})? _pinnedVerse;

  /// Suggestions surfaced by the AI. Each `(slug, label)` pair.
  final List<({String slug, String label})> _suggestions = [];

  /// Slugs the user has currently picked (subset of `_suggestions` + any
  /// pre-existing categories on the entry).
  final Set<String> _selected = <String>{};

  bool get _isEditing => widget.entryId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadExisting();
    } else {
      _loaded = true;
      if (widget.pinnedVerseRef != null) _loadPinnedVerse();
    }
  }

  /// Fetch the chapter containing the pinned verse so we can show its
  /// text in the editor and snapshot it on save.
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
      // Silent — we just won't show the pinned card if fetch fails.
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
      // Pre-existing categories surface as already-selected chips so the user
      // can deselect or re-suggest without losing them.
      for (final slug in entry.categories) {
        _suggestions.add((slug: slug, label: _humanize(slug)));
        _selected.add(slug);
      }
    }
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _suggest() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something first.')),
      );
      return;
    }
    setState(() => _suggesting = true);
    try {
      final result = await ref.read(aiServiceProvider).categorize(text);
      if (!mounted) return;
      setState(() {
        // Merge: keep any already-selected chips, append new suggestions
        // that aren't already in the list.
        for (final s in result) {
          final already =
              _suggestions.any((existing) => existing.slug == s.slug);
          if (!already) {
            _suggestions.add((slug: s.slug, label: s.label));
          }
        }
        // Auto-select new suggestions so the common case is one tap.
        for (final s in result) {
          _selected.add(s.slug);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get suggestions: $e')),
      );
    } finally {
      if (mounted) setState(() => _suggesting = false);
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something first.')),
      );
      return;
    }
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() => _busy = true);
    try {
      final repo = ref.read(journalRepositoryProvider);
      final categories = _selected.toList();
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

  /// Turn a slug like `peace` into a nicer label like `Peace` (used for chips
  /// loaded from an existing entry where we don't have the label).
  static String _humanize(String slug) =>
      slug.isEmpty ? slug : slug[0].toUpperCase() + slug.substring(1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FjColors.cream50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/journal'),
        ),
        title: Text(_isEditing ? 'Edit reflection' : 'New reflection'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _busy ? null : _confirmDelete,
            ),
          TextButton(
            onPressed: _busy || !_loaded ? null : _save,
            child: _busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (_pinnedVerse != null)
                    _PinnedVerseCard(
                      reference: _pinnedVerse!.reference,
                      text: _pinnedVerse!.text,
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: FjSpacing.gutter,
                        vertical: FjSpacing.lg,
                      ),
                      child: TextField(
                        controller: _controller,
                        autofocus: !_isEditing,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        keyboardType: TextInputType.multiline,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                        decoration: InputDecoration(
                          hintText: _pinnedVerse != null
                              ? 'What did this verse stir in you?'
                              : "What's on your heart today?",
                          border: InputBorder.none,
                          filled: false,
                        ),
                      ),
                    ),
                  ),
                  _CategorySection(
                    suggestions: _suggestions,
                    selected: _selected,
                    suggesting: _suggesting,
                    onSuggest: _suggest,
                    onToggle: (slug) {
                      setState(() {
                        if (_selected.contains(slug)) {
                          _selected.remove(slug);
                        } else {
                          _selected.add(slug);
                        }
                      });
                    },
                  ),
                ],
              ),
      ),
    );
  }
}

/// Compact card shown above the text field when a verse is pinned.
class _PinnedVerseCard extends StatelessWidget {
  const _PinnedVerseCard({required this.reference, required this.text});

  final String reference;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        FjSpacing.gutter,
        FjSpacing.md,
        FjSpacing.gutter,
        0,
      ),
      padding: const EdgeInsets.all(FjSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFBF4E8), Color(0xFFF1E2C0)],
        ),
        borderRadius: BorderRadius.circular(FjRadius.card),
        border: Border.all(color: FjColors.gold500.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bookmark,
                size: 16,
                color: FjColors.gold500,
              ),
              const SizedBox(width: 6),
              Text(
                reference,
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: FjColors.navy900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 14,
              height: 1.4,
              fontStyle: FontStyle.italic,
              color: FjColors.navy700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom strip showing AI-suggested category chips + a Suggest button.
class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.suggestions,
    required this.selected,
    required this.suggesting,
    required this.onSuggest,
    required this.onToggle,
  });

  final List<({String slug, String label})> suggestions;
  final Set<String> selected;
  final bool suggesting;
  final VoidCallback onSuggest;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: FjColors.surface0,
        border: Border(top: BorderSide(color: FjColors.gray300)),
      ),
      padding: const EdgeInsets.fromLTRB(
        FjSpacing.gutter,
        FjSpacing.md,
        FjSpacing.gutter,
        FjSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                'Categories',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: FjColors.navy900,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: suggesting ? null : onSuggest,
                icon: suggesting
                    ? const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome, size: 18),
                label: Text(
                  suggestions.isEmpty ? 'Suggest with AI' : 'Re-suggest',
                ),
              ),
            ],
          ),
          if (suggestions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: FjSpacing.sm),
              child: Text(
                'Tap Suggest to let AI pick categories from your text.',
                style: TextStyle(color: FjColors.gray500, fontSize: 13),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions
                  .map(
                    (s) => CategoryChip(
                      label: s.label,
                      selected: selected.contains(s.slug),
                      onTap: () => onToggle(s.slug),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
