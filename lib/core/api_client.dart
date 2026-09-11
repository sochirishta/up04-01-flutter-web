import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:up04_01_flutter_web/core/api_config.dart';

import 'api_exceptions.dart';

class GetRetryInterceptor extends Interceptor {
  GetRetryInterceptor(this._dio);

  final Dio _dio;

  static const int maxRetries = 3;

  bool _isRetryable(DioException error) {
    final method = error.requestOptions.method.toUpperCase();

    if (method != 'GET') {
      return false;
    }

    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError;
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_isRetryable(err)) {
      return handler.next(err);
    }

    final request = err.requestOptions;

    final retryCount = (request.extra['retryCount'] as int?) ?? 0;

    if (retryCount >= maxRetries) {
      return handler.next(err);
    }

    final nextRetry = retryCount + 1;

    final delay = Duration(milliseconds: 300 * nextRetry);

    if (kDebugMode) {
      debugPrint(
        '[API] GET retry $nextRetry/$maxRetries '
        'after ${delay.inMilliseconds}ms: ${request.uri}',
      );
    }

    await Future.delayed(delay);

    if (request.cancelToken?.isCancelled ?? false) {
      return handler.next(err);
    }

    request.extra['retryCount'] = nextRetry;

    try {
      final response = await _dio.fetch(request);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }
}

Dio buildDio({String? Function()? tokenProvider}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenProvider?.call();

        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        if (kDebugMode) {
          debugPrint('[API] ${options.method} ${options.uri}');
        }

        return handler.next(options);
      },

      onResponse: (response, handler) {
        final status = response.statusCode ?? 0;

        if (kDebugMode) {
          debugPrint(
            '[API] ${response.requestOptions.method} '
            '${response.requestOptions.uri} '
            '→ $status',
          );
        }

        if (status >= 400) {
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
        }

        return handler.next(response);
      },

      onError: (error, handler) {
        if (kDebugMode) {
          final request = error.requestOptions;
          final status = error.response?.statusCode;

          if (status == null || status >= 500) {
            debugPrint(
              '[API] ${request.method} ${request.uri} '
              '→ ${status ?? error.type}',
            );
          }
        }

        return handler.next(error);
      },
    ),
  );

  dio.interceptors.add(GetRetryInterceptor(dio));

  return dio;
}
