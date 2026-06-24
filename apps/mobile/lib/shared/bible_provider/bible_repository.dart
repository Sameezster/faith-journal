import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/network/dio_client.dart';

part 'bible_repository.g.dart';

/// Bible repository: fetches from FastAPI /bible and caches chapters on device
/// (Hive/Drift) for offline reading. Cache wiring is a TODO behind this interface.
class BibleRepository {
  BibleRepository(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> getChapter(String translation, String book, int chapter) async {
    // TODO: check local cache first; on miss fetch + cache.
    final res = await _dio.get('/bible/$translation/$book/$chapter');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getBooks(String translation) async {
    final res = await _dio.get('/bible/$translation/books');
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> search(String query, {String? translation}) async {
    final res = await _dio.get('/bible/search', queryParameters: {
      'q': query,
      if (translation != null) 'translation': translation,
    });
    return res.data['results'] as List<dynamic>;
  }
}

@riverpod
BibleRepository bibleRepository(BibleRepositoryRef ref) =>
    BibleRepository(ref.watch(dioProvider));
