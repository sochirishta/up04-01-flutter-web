import 'package:dio/dio.dart';
import 'package:up04_01_flutter_web/models/author.dart';
import 'package:up04_01_flutter_web/models/author_query.dart';
import 'package:up04_01_flutter_web/models/page_result.dart';
import 'package:up04_01_flutter_web/repositories/author_repository.dart';

import '../core/api_exceptions.dart';

class ApiAuthorRepository implements AuthorRepository {
  final Dio _dio;

  ApiAuthorRepository(this._dio);

  @override
  Future<PageResult<Author>> find(AuthorQuery q, {CancelToken? cancelToken}) {
    return guard(() async {
      final response = await _dio.get(
        '/authors',
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
          .map((item) => Author.fromJson(item as Map<String, dynamic>))
          .toList();

      return PageResult<Author>(
        items: items,
        page: data['page'] as int,
        size: data['size'] as int,
        total: data['total'] as int,
      );
    });
  }

  @override
  Future<Author?> findById(int id) {
    return guard(() async {
      final response = await _dio.get('/authors/$id');

      return Author.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<Author?> create(Author author) {
    return guard(() async {
      final response = await _dio.post(
        '/authors',
        data: {
          'fullName': author.fullName,
          'birthYear': author.birthYear,
          'country': author.country,
        },
      );

      return Author.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<Author?> update(Author author) {
    return guard(() async {
      final response = await _dio.put(
        '/authors/${author.id}',
        data: {
          'fullName': author.fullName,
          'birthYear': author.birthYear,
          'country': author.country,
        },
      );

      return Author.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<void> softDelete(int id) {
    return guard(() async {
      await _dio.delete('authors/$id');
    });
  }

  @override
  Future<void> hardDelete(int id) {
    return guard(() async {
      await _dio.delete('authors/$id', queryParameters: {'hard': true});
    });
  }

  @override
  Future<void> restore(int id) {
    return guard(() async {
      await _dio.post('authors/$id/restore');
    });
  }

  @override
  Future<int> deleteMany(List<int> ids) {
    return guard(() async {
      final response = await _dio.post(
        '/authors/bulk-delete',
        data: {'ids': ids},
      );

      final data = response.data as Map<String, dynamic>;

      return data['deleted'] as int;
    });
  }
}
