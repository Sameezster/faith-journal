import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/app_config.dart';

part 'dio_client.g.dart';

/// Provides the current build flavor's config. Override in main() per flavor.
@riverpod
AppConfig appConfig(AppConfigRef ref) => AppConfig.dev;

/// Dio client with an auth interceptor that attaches a fresh Firebase ID token
/// and refreshes on 401.
@riverpod
Dio dio(DioRef ref) {
  final config = ref.watch(appConfigProvider);
  final dio = Dio(BaseOptions(
    baseUrl: config.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    },
    onError: (e, handler) async {
      if (e.response?.statusCode == 401) {
        await FirebaseAuth.instance.currentUser?.getIdToken(true); // force refresh
      }
      handler.next(e);
    },
  ));
  return dio;
}
