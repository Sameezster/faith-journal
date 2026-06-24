import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/network/dio_client.dart';

part 'ai_service.g.dart';

/// A single AI category suggestion (suggest-only; the user accepts/edits/removes).
class CategorySuggestion {
  const CategorySuggestion(this.slug, this.label, this.confidence);
  final String slug;
  final String label;
  final double confidence;

  factory CategorySuggestion.fromJson(Map<String, dynamic> j) =>
      CategorySuggestion(j['slug'] as String, j['label'] as String,
          (j['confidence'] as num).toDouble());
}

/// Calls FastAPI POST /ai/categorize. Never blocks the save flow: callers should
/// treat failures as "no suggestions" and let the user tag manually.
class AiService {
  AiService(this._dio);
  final Dio _dio;

  Future<List<CategorySuggestion>> categorize(
    String text, {
    String context = 'reflection',
    int maxSuggestions = 3,
  }) async {
    final res = await _dio.post('/ai/categorize', data: {
      'text': text,
      'context': context,
      'max_suggestions': maxSuggestions,
    });
    final list = (res.data['suggestions'] as List).cast<Map<String, dynamic>>();
    return list.map(CategorySuggestion.fromJson).toList();
  }
}

@riverpod
AiService aiService(AiServiceRef ref) => AiService(ref.watch(dioProvider));
