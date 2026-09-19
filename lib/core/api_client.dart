import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_config.dart';

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
      handler.next(err);
      return;
    }

    final request = err.requestOptions;
    final retryCount =
        (request.extra['retryCount'] as int?) ?? 0;

    if (retryCount >= maxRetries) {
      handler.next(err);
      return;
    }

    final nextRetry = retryCount + 1;
    final delay = Duration(
      milliseconds: 300 * nextRetry,
    );

    if (kDebugMode) {
      debugPrint(
        '[API] GET retry $nextRetry/$maxRetries '
            'after ${delay.inMilliseconds}ms: ${request.uri}',
      );
    }

    await Future.delayed(delay);

    if (request.cancelToken?.isCancelled ?? false) {
      handler.next(err);
      return;
    }

    request.extra['retryCount'] = nextRetry;

    try {
      final response = await _dio.fetch(request);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.dio,
    required this.tokenProvider,
    required this.refreshToken,
  });

  final Dio dio;
  final String? Function() tokenProvider;
  final Future<String?> Function() refreshToken;

  bool _isAuthRequest(RequestOptions options) {
    final path = options.path;

    return path.contains('/collections/users/auth-with-password') ||
        path.contains('/collections/users/auth-refresh') ||
        path.contains('/collections/users/records');
  }

  @override
  void onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) {
    final token = tokenProvider();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = token;
    }

    if (kDebugMode) {
      debugPrint(
        '[API] ${options.method} ${options.uri}',
      );
    }

    handler.next(options);
  }

  @override
  void onResponse(
      Response response,
      ResponseInterceptorHandler handler,
      ) {
    if (kDebugMode) {
      debugPrint(
        '[API] ${response.requestOptions.method} '
            '${response.requestOptions.uri} '
            '→ ${response.statusCode}',
      );
    }

    handler.next(response);
  }

  @override
  Future<void> onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    final request = err.requestOptions;
    final response = err.response;
    final status = response?.statusCode;

    if (kDebugMode) {
      debugPrint(
        '[API] ${request.method} ${request.uri} '
            '→ ${status ?? err.type}',
      );
    }

    if (status != 401) {
      handler.next(err);
      return;
    }

    if (_isAuthRequest(request)) {
      handler.next(err);
      return;
    }

    if (request.extra['authRetry'] == true) {
      handler.next(err);
      return;
    }

    try {
      final newAccessToken = await refreshToken();

      if (newAccessToken == null ||
          newAccessToken.isEmpty) {
        handler.next(err);
        return;
      }

      request.extra['authRetry'] = true;

      request.headers['Authorization'] =
          newAccessToken;

      if (kDebugMode) {
        debugPrint(
          '[API] retry after token refresh: '
              '${request.method} ${request.uri}',
        );
      }

      final retryResponse = await dio.fetch(request);

      handler.resolve(retryResponse);
    } on DioException catch (e) {
      handler.next(e);
    } catch (e) {
      handler.next(
        DioException(
          requestOptions: request,
          response: response,
          type: DioExceptionType.unknown,
          error: e,
        ),
      );
    }
  }
}

Dio buildDio({
  String? Function()? tokenProvider,
  Future<String?> Function()? refreshToken,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
      },
      validateStatus: (status) {
        return status != null &&
            status >= 200 &&
            status < 300;
      },
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      tokenProvider:
      tokenProvider ?? () => null,
      refreshToken:
      refreshToken ?? () async => null,
    ),
  );

  dio.interceptors.add(
    GetRetryInterceptor(dio),
  );

  return dio;
}