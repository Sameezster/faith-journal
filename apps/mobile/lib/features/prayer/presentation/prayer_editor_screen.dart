import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/prayer/prayer_categories.dart';
import '../../../shared/prayer/prayer_providers.dart';
import '../../../shared/prayer/prayer_request.dart';
import '../../auth/presentation/providers/auth_providers.dart';

/// Full-screen editor for creating or editing a prayer request.
/// Pass [requestId] to edit; null = create.
class PrayerEditorScreen extends ConsumerStatefulWidget {
  const PrayerEditorScreen({super.key, this.requestId});

  final String? requestId;

  @override
  ConsumerState<PrayerEditorScreen> createState() => _PrayerEditorScreenState();
}

class _PrayerEditorScreenState extends ConsumerState<PrayerEditorScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String? _category;
  DateTime _date = DateTime.now();
  PrayerStatus _status = PrayerStatus.active;
  bool _busy = false;
  bool _loaded = false;

  bool get _isEditing => widget.requestId != null;

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
    final r = await ref
        .read(prayerRepositoryProvider)
        .getRequest(user.uid, widget.requestId!);
    if (!mounted) return;
    if (r != null) {
      _titleController.text = r.title;
      _descController.text = r.description;
      _category = r.category;
      _date = r.date ?? r.createdAt ?? DateTime.now();
      _status = r.status;
    }
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _pickCategory() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: FjColors.surface0,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(FjRadius.cardLg)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: FjSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  FjSpacing.gutter,
                  FjSpacing.sm,
                  FjSpacing.gutter,
                  FjSpacing.md,
                ),
                child: Row(
                  children: [
                    Text(
                      'Choose a category',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: FjColors.navy900,
                      ),
                    ),
                  ],
                ),
              ),
              for (final c in kPrayerCategories)
                ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(c.icon, color: c.color, size: 20),
                  ),
                  title: Text(c.label),
                  trailing: _category == c.slug
                      ? const Icon(Icons.check, color: FjColors.gold500)
                      : null,
                  onTap: () => Navigator.pop(ctx, c.slug),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _category = picked);
  }

  Future<void> _save() async {
    if (_busy) return;
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your prayer a title first.')),
      );
      return;
    }
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() => _busy = true);
    try {
      final repo = ref.read(prayerRepositoryProvider);
      if (_isEditing) {
        await repo.updateRequest(
          user.uid,
          widget.requestId!,
          title: title,
          description: desc,
          status: _status,
          category: _category,
          clearCategory: _category == null,
          date: _date,
        );
      } else {
        await repo.createRequest(
          user.uid,
          title: title,
          description: desc,
          status: _status,
          category: _category,
          date: _date,
        );
      }
      if (!mounted) return;
      context.go('/prayer');
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
        title: const Text('Delete prayer?'),
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
          .read(prayerRepositoryProvider)
          .deleteRequest(user.uid, widget.requestId!);
      if (!mounted) return;
      context.go('/prayer');
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
          icon: const Icon(Icons.arrow_back, color: FjColors.gold500),
          onPressed: () => context.go('/prayer'),
        ),
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
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  FjSpacing.gutter,
                  0,
                  FjSpacing.gutter,
                  FjSpacing.xxl,
                ),
                children: [
                  const _Header(),
                  const SizedBox(height: FjSpacing.xxl),
                  _FormCard(
                    label: 'Title',
                    child: TextField(
                      controller: _titleController,
                      decoration:
                          _outlinedField('Enter a title for your prayer'),
                    ),
                  ),
                  const SizedBox(height: FjSpacing.lg),
                  _FormCard(
                    label: 'Description',
                    child: TextField(
                      controller: _descController,
                      maxLines: 5,
                      minLines: 5,
                      decoration: _outlinedField(
                        'Write your prayer request in detail…',
                      ),
                    ),
                  ),
                  const SizedBox(height: FjSpacing.lg),
                  _FormCard(
                    label: 'Category',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(FjRadius.input),
                      onTap: _pickCategory,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: FjSpacing.md,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(FjRadius.input),
                          border: Border.all(color: FjColors.gray300),
                        ),
                        child: _CategorySelectionRow(slug: _category),
                      ),
                    ),
                  ),
                  const SizedBox(height: FjSpacing.lg),
                  _FormCard(
                    label: 'Date',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(FjRadius.input),
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: FjSpacing.md,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(FjRadius.input),
                          border: Border.all(color: FjColors.gray300),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              color: FjColors.sage500,
                              size: 18,
                            ),
                            const SizedBox(width: FjSpacing.md),
                            Expanded(
                              child: Text(
                                _formatDate(_date),
                                style: const TextStyle(
                                  color: FjColors.navy900,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today,
                              color: FjColors.gold500,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: FjSpacing.lg),
                    _FormCard(
                      label: 'Status',
                      child: _StatusRow(
                        selected: _status,
                        onChanged: (s) => setState(() => _status = s),
                      ),
                    ),
                  ],
                  const SizedBox(height: FjSpacing.xxl),
                  _SaveButton(busy: _busy, onTap: _save),
                ],
              ),
      ),
    );
  }

  InputDecoration _outlinedField(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: FjColors.gray500),
        filled: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: FjSpacing.md,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FjRadius.input),
          borderSide: const BorderSide(color: FjColors.gray300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FjRadius.input),
          borderSide: const BorderSide(color: FjColors.gold500, width: 1.5),
        ),
      );

  static String _formatDate(DateTime d) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _EditorIllustration(),
        SizedBox(height: FjSpacing.md),
        Text(
          'New Prayer',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.w700,
            fontSize: 32,
            color: FjColors.navy900,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Lift your heart to God and share your request.',
          style: TextStyle(color: FjColors.gray500, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Stylized cross-and-laurel illustration built from icons.
/// Replace with `Image.asset('assets/illustrations/prayer_header.png')` when
/// real artwork is available.
class _EditorIllustration extends StatelessWidget {
  const _EditorIllustration();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 120,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Sparkle halo above the cross
          Positioned(
            top: 0,
            child: Icon(Icons.auto_awesome, size: 20, color: FjColors.gold500),
          ),
          // Cross
          Positioned(
            top: 10,
            child: Icon(Icons.add, size: 32, color: FjColors.gold500),
          ),
          // Laurel branches (identical icons on either side; replace with
          // real artwork when available).
          Positioned(
            bottom: 0,
            left: 12,
            child: Icon(Icons.spa_outlined, size: 26, color: FjColors.sage500),
          ),
          Positioned(
            bottom: 0,
            right: 12,
            child: Icon(Icons.spa_outlined, size: 26, color: FjColors.sage500),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.label, required this.child});
  final String label;
  final Widget child;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: FjColors.navy900,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: FjSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _CategorySelectionRow extends StatelessWidget {
  const _CategorySelectionRow({required this.slug});
  final String? slug;

  @override
  Widget build(BuildContext context) {
    final cat = findPrayerCategory(slug);
    if (cat == null) {
      return const Row(
        children: [
          Icon(Icons.label_outline, color: FjColors.sage500, size: 18),
          SizedBox(width: FjSpacing.md),
          Expanded(
            child: Text(
              'Select a category',
              style: TextStyle(color: FjColors.gray500, fontSize: 15),
            ),
          ),
          Icon(Icons.keyboard_arrow_down, color: FjColors.gold500),
        ],
      );
    }
    return Row(
      children: [
        Icon(cat.icon, color: cat.color, size: 18),
        const SizedBox(width: FjSpacing.md),
        Expanded(
          child: Text(
            cat.label,
            style: const TextStyle(color: FjColors.navy900, fontSize: 15),
          ),
        ),
        const Icon(Icons.keyboard_arrow_down, color: FjColors.gold500),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.selected, required this.onChanged});
  final PrayerStatus selected;
  final ValueChanged<PrayerStatus> onChanged;

  Color _colorOf(PrayerStatus s) => switch (s) {
        PrayerStatus.active => FjColors.statusActive,
        PrayerStatus.waiting => FjColors.statusWaiting,
        PrayerStatus.answered => FjColors.statusAnswered,
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: PrayerStatus.values.map((s) {
        final isSelected = s == selected;
        final color = _colorOf(s);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(FjRadius.chip),
              onTap: () => onChanged(s),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.15)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? color : FjColors.gray300,
                  ),
                  borderRadius: BorderRadius.circular(FjRadius.chip),
                ),
                alignment: Alignment.center,
                child: Text(
                  s.label,
                  style: TextStyle(
                    color: isSelected ? color : FjColors.gray500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
                  strokeWidth: 2, color: Colors.white),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.volunteer_activism_outlined, size: 20),
                SizedBox(width: 8),
                Text(
                  'Save Prayer',
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
