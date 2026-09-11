import 'package:dio/dio.dart';
import 'package:up04_01_flutter_web/models/genre.dart';
import 'package:up04_01_flutter_web/models/genre_query.dart';
import 'package:up04_01_flutter_web/models/page_result.dart';
import 'package:up04_01_flutter_web/repositories/genre_repository.dart';

import '../core/api_exceptions.dart';

class ApiGenreRepository implements GenreRepository {
  final Dio _dio;

  ApiGenreRepository(this._dio);

  @override
  Future<PageResult<Genre>> find(GenreQuery q, {CancelToken? cancelToken}) {
    return guard(() async {
      final response = await _dio.get(
        '/genres',
        queryParameters: {
          if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
          'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
          'page': q.page,
          'size': q.size,
          if (q.includeDeleted) 'includeDeleted': true,
        },
        cancelToken: cancelToken,
      );

      final data = response.data as Map<String, dynamic>;

      final items = (data['items'] as List)
          .map((item) => Genre.fromJson(item as Map<String, dynamic>))
          .toList();

      return PageResult<Genre>(
        items: items,
        page: data['page'] as int,
        size: data['size'] as int,
        total: data['total'] as int,
      );
    });
  }

  @override
  Future<Genre?> findById(int id) {
    return guard(() async {
      final response = await _dio.get('/genres/$id');

      return Genre.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<Genre> create(Genre genre) {
    return guard(() async {
      final response = await _dio.post(
        '/genres',
        data: {'name': genre.name, 'description': genre.description},
      );

      return Genre.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<Genre> update(Genre genre) {
    return guard(() async {
      final response = await _dio.put(
        '/genres/${genre.id}',
        data: {'name': genre.name, 'description': genre.description},
      );

      return Genre.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<void> delete(int id) {
    return guard(() async {
      await _dio.delete('genres/$id');
    });
  }

  @override
  Future<int> deleteMany(List<int> ids) {
    return guard(() async {
      final response = await _dio.post(
        '/genres/bulk-delete',
        data: {'ids': ids},
      );

      final data = response.data as Map<String, dynamic>;

      return data['deleted'] as int;
    });
  }

  @override
  Future<void> restore(int id) {
    return guard(() async {
      await _dio.post('genres/$id/restore');
    });
  }

  @override
  Future<void> hardDelete(int id) {
    return guard(() async {
      await _dio.delete('genres/$id', queryParameters: {'hard': true});
    });
  }
}
