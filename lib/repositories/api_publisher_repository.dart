import 'package:dio/dio.dart';
import 'package:up04_01_flutter_web/models/page_result.dart';
import 'package:up04_01_flutter_web/models/publisher.dart';
import 'package:up04_01_flutter_web/models/publisher_query.dart';
import 'package:up04_01_flutter_web/repositories/publisher_repository.dart';

import '../core/api_exceptions.dart';

class ApiPublisherRepository implements PublisherRepository {
  final Dio _dio;

  ApiPublisherRepository(this._dio);

  @override
  Future<PageResult<Publisher>> find(
    PublisherQuery q, {
    CancelToken? cancelToken,
  }) {
    return guard(() async {
      final response = await _dio.get(
        '/publishers',
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
          .map((item) => Publisher.fromJson(item as Map<String, dynamic>))
          .toList();

      return PageResult<Publisher>(
        items: items,
        page: data['page'] as int,
        size: data['size'] as int,
        total: data['total'] as int,
      );
    });
  }

  @override
  Future<Publisher?> findById(int id) {
    return guard(() async {
      final response = await _dio.get('/publishers/$id');

      return Publisher.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<Publisher> create(Publisher publisher) {
    return guard(() async {
      final response = await _dio.post(
        '/publishers',
        data: {
          'name': publisher.name,
          'city': publisher.city,
          'foundedYear': publisher.foundedYear,
        },
      );

      return Publisher.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<Publisher> update(Publisher publisher) {
    return guard(() async {
      final response = await _dio.put(
        '/publishers/${publisher.id}',
        data: {
          'name': publisher.name,
          'city': publisher.city,
          'foundedYear': publisher.foundedYear,
        },
      );

      return Publisher.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<void> delete(int id) {
    return guard(() async {
      await _dio.delete('publishers/$id');
    });
  }

  @override
  Future<int> deleteMany(List<int> ids) {
    return guard(() async {
      final response = await _dio.post(
        '/publishers/bulk-delete',
        data: {'ids': ids},
      );

      final data = response.data as Map<String, dynamic>;

      return data['deleted'] as int;
    });
  }

  @override
  Future<void> restore(int id) {
    return guard(() async {
      await _dio.post('publishers/$id/restore');
    });
  }

  @override
  Future<void> hardDelete(int id) {
    return guard(() async {
      await _dio.delete('publishers/$id', queryParameters: {'hard': true});
    });
  }
}
