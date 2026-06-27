import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/network/dio_client.dart';
import 'bible_models.dart';
import 'bible_repository.dart';

part 'bible_providers.g.dart';

@riverpod
BibleRepository bibleRepository(BibleRepositoryRef ref) =>
    BibleRepository(ref.watch(dioProvider));

@riverpod
Future<List<Translation>> translations(TranslationsRef ref) =>
    ref.watch(bibleRepositoryProvider).getTranslations();

@riverpod
Future<BookList> books(BooksRef ref, String translation) =>
    ref.watch(bibleRepositoryProvider).getBooks(translation);

@riverpod
Future<Chapter> bibleChapter(
  BibleChapterRef ref,
  String translation,
  String book,
  int chapter,
) =>
    ref.watch(bibleRepositoryProvider).getChapter(translation, book, chapter);

@riverpod
Future<List<SearchHit>> bibleSearch(
  BibleSearchRef ref, {
  required String query,
  String? translation,
}) =>
    ref.watch(bibleRepositoryProvider).search(query, translation: translation);

/// The translation the user is currently browsing. Defaults to KJV.
/// Persistence to Firestore (`users/{uid}.preferredTranslation`) is a TODO.
@riverpod
class SelectedTranslation extends _$SelectedTranslation {
  @override
  String build() => 'KJV';

  void set(String code) => state = code;
}
