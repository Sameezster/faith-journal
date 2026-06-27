import 'package:dio/dio.dart';

import 'bible_models.dart';

/// Bible repository — fetches from FastAPI `/bible/*` endpoints and returns
/// typed models. On-device cache (Hive/Drift) for offline reading is a TODO.
class BibleRepository {
  BibleRepository(this._dio);
  final Dio _dio;

  Future<List<Translation>> getTranslations() async {
    final res = await _dio.get('/bible/translations');
    final list =
        (res.data['translations'] as List).cast<Map<String, dynamic>>();
    return list.map(Translation.fromJson).toList();
  }

  Future<BookList> getBooks(String translation) async {
    final res = await _dio.get('/bible/$translation/books');
    return BookList.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Chapter> getChapter(
      String translation, String book, int chapter) async {
    final res = await _dio.get('/bible/$translation/$book/$chapter');
    return Chapter.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<SearchHit>> search(
    String query, {
    String? translation,
    int limit = 50,
  }) async {
    final res = await _dio.get(
      '/bible/search',
      queryParameters: {
        'q': query,
        if (translation != null) 'translation': translation,
        'limit': limit,
      },
    );
    final list = (res.data['results'] as List).cast<Map<String, dynamic>>();
    return list.map(SearchHit.fromJson).toList();
  }
}
