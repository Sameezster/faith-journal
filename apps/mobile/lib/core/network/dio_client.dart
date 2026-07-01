import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/app_config.dart';

part 'dio_client.g.dart';

/// Provides the current build flavor's config. Override in main() per flavor.
/// `main()` overrides this with a runtime-resolved AppConfig that picks the
/// right dev host based on the device (emulator vs physical phone).
@riverpod
AppConfig appConfig(AppConfigRef ref) => AppConfig.devFallback;

/// Dio client with:
///   - Firebase ID token attached as a Bearer token on every request
///   - Forced ID-token refresh on 401
///   - One automatic retry on transient errors (timeout, 5xx, no-connection)
///     so the user doesn't see "Could not load books" the first time their
///     phone wakes up and WiFi is still reconnecting.
@riverpod
Dio dio(DioRef ref) {
  final config = ref.watch(appConfigProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 20),
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await FirebaseAuth.instance.currentUser?.getIdToken();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (e, handler) async {
        // Force refresh on auth failure, but don't retry — let the caller
        // decide what to do with the 401.
        if (e.response?.statusCode == 401) {
          await FirebaseAuth.instance.currentUser?.getIdToken(true);
          return handler.next(e);
        }

        if (_isRetryable(e) && e.requestOptions.extra['_retried'] != true) {
          // One retry after a short delay. Mark the options so we don't loop.
          await Future<void>.delayed(const Duration(milliseconds: 600));
          final retryOptions = e.requestOptions
            ..extra['_retried'] = true;
          try {
            final response = await dio.fetch<dynamic>(retryOptions);
            return handler.resolve(response);
          } catch (_) {
            // Fall through to the original error.
          }
        }
        handler.next(e);
      },
    ),
  );
  return dio;
}

bool _isRetryable(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return true;
    case DioExceptionType.badResponse:
      final code = e.response?.statusCode ?? 0;
      return code >= 500;
    case DioExceptionType.cancel:
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      return false;
  }
}
