import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/genre.dart';
import '../models/genre_query.dart';
import '../models/page_result.dart';
import 'genre_repository.dart';

class ApiGenreRepository implements GenreRepository {
  final Dio _dio;

  ApiGenreRepository(this._dio);

  @override
  Future<PageResult<Genre>> find(
      GenreQuery q, {
        CancelToken? cancelToken,
      }) {
    return guard(() async {
      final filters = <String>[];

      if (q.search.trim().isNotEmpty) {
        final value = q.search.trim().replaceAll('"', r'\"');
        filters.add('name ~ "$value"');
      }

      if (!q.includeDeleted) {
        filters.add('deletedAt = ""');
      }

      final response = await _dio.get(
        '/collections/genres/records',
        queryParameters: {
          'page': q.page,
          'perPage': q.size,
          'sort': '${q.sortAscending ? '+' : '-'}${q.sortField}',
          if (filters.isNotEmpty) 'filter': filters.join(' && '),
        },
        cancelToken: cancelToken,
      );

      return _pageResult(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<Genre?> findById(String id) {
    return guard(() async {
      final response = await _dio.get(
        '/collections/genres/records/$id',
      );

      return Genre.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  @override
  Future<Genre?> create(Genre genre) {
    return guard(() async {
      final response = await _dio.post(
        '/collections/genres/records',
        data: {
          'name': genre.name,
          'deletedAt': '',
        },
      );

      return Genre.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  @override
  Future<Genre?> update(Genre genre) {
    return guard(() async {
      final response = await _dio.patch(
        '/collections/genres/records/${genre.id}',
        data: {
          'name': genre.name,
        },
      );

      return Genre.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  @override
  Future<void> softDelete(String id) {
    return guard(() async {
      await _dio.patch(
        '/collections/genres/records/$id',
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
        '/collections/genres/records/$id',
      );
    });
  }

  @override
  Future<void> restore(String id) {
    return guard(() async {
      await _dio.patch(
        '/collections/genres/records/$id',
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

  PageResult<Genre> _pageResult(Map<String, dynamic> data) {
    final items = (data['items'] as List<dynamic>)
        .map(
          (item) => Genre.fromJson(
        item as Map<String, dynamic>,
      ),
    )
        .toList();

    return PageResult<Genre>(
      items: items,
      page: (data['page'] as num).toInt(),
      size: (data['perPage'] as num).toInt(),
      total: (data['totalItems'] as num).toInt(),
    );
  }
}