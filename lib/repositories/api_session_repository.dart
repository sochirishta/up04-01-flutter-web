import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/page_result.dart';
import '../models/session.dart';
import '../models/session_query.dart';
import 'session_repository.dart';

class ApiSessionRepository implements SessionRepository {
  final Dio _dio;

  ApiSessionRepository(this._dio);

  @override
  Future<PageResult<CinemaSession>> find(
      SessionQuery q, {
        CancelToken? cancelToken,
      }) {
    return guard(() async {
      final filters = <String>[];

      if (q.movieId != null && q.movieId!.isNotEmpty) {
        filters.add('movie = "${q.movieId}"');
      }

      if (q.hallId != null && q.hallId!.isNotEmpty) {
        filters.add('hall = "${q.hallId}"');
      }

      if (q.dateFrom != null) {
        filters.add(
          'date >= "${q.dateFrom!.toUtc().toIso8601String()}"',
        );
      }

      if (q.dateTo != null) {
        filters.add(
          'date <= "${q.dateTo!.toUtc().toIso8601String()}"',
        );
      }

      if (!q.includeDeleted) {
        filters.add('deletedAt = ""');
      }

      final response = await _dio.get(
        '/collections/sessions/records',
        queryParameters: {
          'page': q.page,
          'perPage': q.size,
          'sort': '${q.sortAscending ? '+' : '-'}${q.sortField}',
          if (filters.isNotEmpty) 'filter': filters.join(' && '),
          'expand': 'movie,hall',
        },
        cancelToken: cancelToken,
      );

      return _pageResult(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<CinemaSession?> findById(String id) {
    return guard(() async {
      final response = await _dio.get(
        '/collections/sessions/records/$id',
        queryParameters: {
          'expand': 'movie,hall',
        },
      );

      return CinemaSession.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  @override
  Future<CinemaSession?> create(CinemaSession session) {
    return guard(() async {
      final response = await _dio.post(
        '/collections/sessions/records',
        data: {
          'movie': session.movieId,
          'hall': session.hallId,
          'date': session.date.toUtc().toIso8601String(),
          'deletedAt': '',
        },
      );

      return CinemaSession.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  @override
  Future<CinemaSession?> update(CinemaSession session) {
    return guard(() async {
      final response = await _dio.patch(
        '/collections/sessions/records/${session.id}',
        data: {
          'movie': session.movieId,
          'hall': session.hallId,
          'date': session.date.toUtc().toIso8601String(),
        },
      );

      return CinemaSession.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  @override
  Future<void> softDelete(String id) {
    return guard(() async {
      await _dio.patch(
        '/collections/sessions/records/$id',
        data: {
          'deletedAt': DateTime.now().toUtc().toIso8601String(),
        },
      );
    });
  }

  @override
  Future<void> hardDelete(String id) {
    return guard(() async {
      await _dio.delete(
        '/collections/sessions/records/$id',
      );
    });
  }

  @override
  Future<void> restore(String id) {
    return guard(() async {
      await _dio.patch(
        '/collections/sessions/records/$id',
        data: {
          'deletedAt': '',
        },
      );
    });
  }

  @override
  Future<int> deleteMany(List<String> ids) async {
    var count = 0;

    for (final id in ids) {
      try {
        await softDelete(id);
        count++;
      } on ApiException {
        // Continue with the remaining records.
      }
    }

    return count;
  }

  PageResult<CinemaSession> _pageResult(
      Map<String, dynamic> data,
      ) {
    final items = (data['items'] as List<dynamic>)
        .map(
          (item) => CinemaSession.fromJson(
        item as Map<String, dynamic>,
      ),
    )
        .toList();

    return PageResult<CinemaSession>(
      items: items,
      page: (data['page'] as num).toInt(),
      size: (data['perPage'] as num).toInt(),
      total: (data['totalItems'] as num).toInt(),
    );
  }
}