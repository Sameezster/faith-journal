import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/journal/journal_providers.dart';
import '../../auth/presentation/providers/auth_providers.dart';

/// Full-screen editor for creating or editing a journal entry.
/// Pass [entryId] to edit; null = create.
class JournalEditorScreen extends ConsumerStatefulWidget {
  const JournalEditorScreen({super.key, this.entryId});

  final String? entryId;

  @override
  ConsumerState<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends ConsumerState<JournalEditorScreen> {
  final _controller = TextEditingController();
  bool _busy = false;
  bool _loaded = false;

  bool get _isEditing => widget.entryId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadExisting();
    } else {
      _loaded = true;
    }
  }

  Future<void> _loadExisting() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final entry = await ref
        .read(journalRepositoryProvider)
        .getEntry(user.uid, widget.entryId!);
    if (!mounted) return;
    if (entry != null) _controller.text = entry.text;
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
        const SnackBar(content: Text('Write something first.')),
      );
      return;
    }
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() => _busy = true);
    try {
      final repo = ref.read(journalRepositoryProvider);
      if (_isEditing) {
        await repo.updateEntry(user.uid, widget.entryId!, text: text);
      } else {
        await repo.createEntry(user.uid, text: text);
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
            : Padding(
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
                  decoration: const InputDecoration(
                    hintText: "What's on your heart today?",
                    border: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),
      ),
    );
  }
}
