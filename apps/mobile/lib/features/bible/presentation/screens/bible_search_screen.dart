import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/bible_provider/bible_models.dart';
import '../../../../shared/bible_provider/bible_providers.dart';

/// Verse search. Debounces input by 350ms to avoid hammering the API
/// while the user types.
class BibleSearchScreen extends ConsumerStatefulWidget {
  const BibleSearchScreen({super.key});

  @override
  ConsumerState<BibleSearchScreen> createState() => _BibleSearchScreenState();
}

class _BibleSearchScreenState extends ConsumerState<BibleSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translation = ref.watch(selectedTranslationProvider);

    return Scaffold(
      backgroundColor: FjColors.cream50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/bible'),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search verses…',
            border: InputBorder.none,
          ),
          onChanged: _onChanged,
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _controller.clear();
                _onChanged('');
              },
            ),
        ],
      ),
      body: SafeArea(
        child: _query.isEmpty
            ? const _Hint()
            : _Results(query: _query, translation: translation),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(FjSpacing.xxl),
        child: Text(
          'Type at least one word to search.\nTry "love", "peace", or "faith".',
          textAlign: TextAlign.center,
          style: TextStyle(color: FjColors.gray500),
        ),
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.query, required this.translation});

  final String query;
  final String translation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(
      bibleSearchProvider(query: query, translation: translation),
    );

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(FjSpacing.xxl),
          child: Text('Search failed.\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: FjColors.gray500)),
        ),
      ),
      data: (hits) => hits.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(FjSpacing.xxl),
                child: Text('No matches.',
                    style: TextStyle(color: FjColors.gray500)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(FjSpacing.gutter),
              itemCount: hits.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: FjSpacing.sm),
              itemBuilder: (_, i) => _Hit(hit: hits[i], query: query),
            ),
    );
  }
}

class _Hit extends StatelessWidget {
  const _Hit({required this.hit, required this.query});

  final SearchHit hit;
  final String query;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(FjRadius.card),
        onTap: () => context.go(
          '/bible/${hit.translation}/${hit.book}/${hit.chapter}',
        ),
        child: Padding(
          padding: const EdgeInsets.all(FjSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${hit.reference} · ${hit.translation}',
                style: const TextStyle(
                  color: FjColors.gold500,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              _Highlighted(text: hit.text, query: query),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bolds occurrences of [query] inside [text] (case-insensitive).
class _Highlighted extends StatelessWidget {
  const _Highlighted({required this.text, required this.query});
  final String text;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return Text(text);
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    var i = 0;
    while (i < text.length) {
      final j = lowerText.indexOf(lowerQuery, i);
      if (j < 0) {
        spans.add(TextSpan(text: text.substring(i)));
        break;
      }
      if (j > i) spans.add(TextSpan(text: text.substring(i, j)));
      spans.add(
        TextSpan(
          text: text.substring(j, j + query.length),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
      i = j + query.length;
    }
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: FjColors.navy900,
          fontSize: 15,
          height: 1.4,
        ),
        children: spans,
      ),
    );
  }
}
