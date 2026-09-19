import 'package:dio/dio.dart';

sealed class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'Сервер недоступен. Проверьте соединение.',
  ]);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([
    super.message = 'Требуется вход в систему.',
  ]);
}

class ForbiddenException extends ApiException {
  const ForbiddenException([
    super.message = 'Недостаточно прав для этого действия.',
  ]);
}

class NotFoundException extends ApiException {
  const NotFoundException([
    super.message = 'Запись не найдена.',
  ]);
}

class ConflictException extends ApiException {
  const ConflictException([
    super.message = 'Операция вызвала конфликт данных.',
  ]);
}

class ValidationException extends ApiException {
  final Map<String, String> errors;

  const ValidationException(
      super.message,
      this.errors,
      );
}

class ServerException extends ApiException {
  const ServerException([
    super.message = 'Ошибка на сервере. Попробуйте позже.',
  ]);
}

ApiException mapHttpError(
    int status,
    dynamic body,
    ) {
  final message = body is Map && body['message'] is String
      ? body['message'] as String
      : null;

  if (status == 400) {
    return ValidationException(
      message ?? 'Ошибка проверки данных.',
      _extractValidationErrors(body),
    );
  }

  return switch (status) {
    401 => UnauthorizedException(
      message ?? 'Требуется вход в систему.',
    ),
    403 => ForbiddenException(
      message ?? 'Недостаточно прав для этого действия.',
    ),
    404 => NotFoundException(
      message ?? 'Запись не найдена.',
    ),
    409 => ConflictException(
      message ?? 'Операция вызвала конфликт данных.',
    ),
    422 => ValidationException(
      message ?? 'Ошибка валидации.',
      _extractValidationErrors(body),
    ),
    _ => ServerException(
      message ?? 'Неизвестная ошибка (код $status).',
    ),
  };
}

Map<String, String> _extractValidationErrors(
    dynamic body,
    ) {
  if (body is! Map) {
    return const {};
  }

  final data = body['data'];

  if (data is! Map) {
    return const {};
  }

  return data.map(
        (key, value) {
      if (value is Map && value['message'] is String) {
        return MapEntry(
          '$key',
          value['message'] as String,
        );
      }

      return MapEntry(
        '$key',
        '$value',
      );
    },
  );
}

ApiException mapDioError(DioException e) {
  final existing = e.error;

  if (existing is ApiException) {
    return existing;
  }

  final status = e.response?.statusCode;

  if (status != null) {
    return mapHttpError(
      status,
      e.response?.data,
    );
  }

  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout =>
    const NetworkException(
      'Сервер не ответил вовремя.',
    ),

    DioExceptionType.connectionError =>
    const NetworkException(
      'Не удалось соединиться с PocketBase. '
          'Убедитесь, что сервер запущен.',
    ),

    DioExceptionType.cancel =>
    const NetworkException(
      'Запрос отменён.',
    ),

    _ => const ServerException(),
  };
}

Future<T> guard<T>(
    Future<T> Function() action,
    ) async {
  try {
    return await action();
  } on DioException catch (e) {
    throw mapDioError(e);
  }
}