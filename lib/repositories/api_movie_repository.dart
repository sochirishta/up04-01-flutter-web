import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/movie.dart';
import '../models/movie_query.dart';
import '../models/page_result.dart';
import 'movie_repository.dart';

class ApiMovieRepository implements MovieRepository {
  final Dio _dio;

  ApiMovieRepository(this._dio);

  @override
  Future<PageResult<Movie>> find(
      MovieQuery q, {
        CancelToken? cancelToken,
      }) {
    return guard(() async {
      final filters = <String>[];

      if (q.search.trim().isNotEmpty) {
        final value = q.search.trim().replaceAll('"', r'\"');
        filters.add('title ~ "$value"');
      }

      if (q.yearFrom != null) {
        filters.add('year >= ${q.yearFrom}');
      }

      if (q.yearTo != null) {
        filters.add('year <= ${q.yearTo}');
      }

      if (q.durationFrom != null) {
        filters.add('duration >= ${q.durationFrom}');
      }

      if (q.durationTo != null) {
        filters.add('duration <= ${q.durationTo}');
      }

      if (!q.includeDeleted) {
        filters.add('deletedAt = ""');
      }

      if (q.genreId != null && q.genreId!.isNotEmpty) {
        filters.add('genres ?= "${q.genreId}"');
      }

      if (q.personId != null && q.personId!.isNotEmpty) {
        filters.add('persons ?= "${q.personId}"');
      }

      final response = await _dio.get(
        '/collections/movies/records',
        queryParameters: {
          'page': q.page,
          'perPage': q.size,
          'sort': '${q.sortAscending ? '+' : '-'}${q.sortField}',
          if (filters.isNotEmpty) 'filter': filters.join(' && '),
          'expand': 'genres,persons',
        },
        cancelToken: cancelToken,
      );

      return _pageResult(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<Movie?> findById(String id) {
    return guard(() async {
      final response = await _dio.get(
        '/collections/movies/records/$id',
        queryParameters: {
          'expand': 'genres,persons',
        },
      );

      return Movie.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  @override
  Future<Movie?> create(Movie movie) {
    return guard(() async {
      final response = await _dio.post(
        '/collections/movies/records',
        data: {
          'title': movie.title,
          'year': movie.year,
          'duration': movie.duration,
          'genres': movie.genreIds,
          'persons': movie.personIds,
          'deletedAt': '',
        },
      );

      return Movie.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  @override
  Future<Movie?> update(Movie movie) {
    return guard(() async {
      final response = await _dio.patch(
        '/collections/movies/records/${movie.id}',
        data: {
          'title': movie.title,
          'year': movie.year,
          'duration': movie.duration,
          'genres': movie.genreIds,
          'persons': movie.personIds,
        },
      );

      return Movie.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  @override
  Future<void> softDelete(String id) {
    return guard(() async {
      await _dio.patch(
        '/collections/movies/records/$id',
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
        '/collections/movies/records/$id',
      );
    });
  }

  @override
  Future<void> restore(String id) {
    return guard(() async {
      await _dio.patch(
        '/collections/movies/records/$id',
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
        // Continue deleting the remaining records.
      }
    }

    return count;
  }

  PageResult<Movie> _pageResult(Map<String, dynamic> data) {
    final items = (data['items'] as List<dynamic>)
        .map(
          (item) => Movie.fromJson(
        item as Map<String, dynamic>,
      ),
    )
        .toList();

    return PageResult<Movie>(
      items: items,
      page: (data['page'] as num).toInt(),
      size: (data['perPage'] as num).toInt(),
      total: (data['totalItems'] as num).toInt(),
    );
  }
}