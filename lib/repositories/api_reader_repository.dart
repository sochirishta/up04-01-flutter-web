import 'package:dio/dio.dart';
import 'package:up04_01_flutter_web/models/page_result.dart';
import 'package:up04_01_flutter_web/models/reader.dart';
import 'package:up04_01_flutter_web/models/reader_query.dart';
import 'package:up04_01_flutter_web/repositories/reader_repository.dart';

import '../core/api_exceptions.dart';

class ApiReaderRepository implements ReaderRepository {
  final Dio _dio;

  ApiReaderRepository(this._dio);

  @override
  Future<PageResult<Reader>> find(ReaderQuery q, {CancelToken? cancelToken}) {
    return guard(() async {
      final response = await _dio.get(
        '/readers',
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
          .map((item) => Reader.fromJson(item as Map<String, dynamic>))
          .toList();

      return PageResult<Reader>(
        items: items,
        page: data['page'] as int,
        size: data['size'] as int,
        total: data['total'] as int,
      );
    });
  }

  @override
  Future<Reader?> findById(int id) {
    return guard(() async {
      final response = await _dio.get('/readers/$id');

      return Reader.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<Reader> create(Reader reader) {
    return guard(() async {
      final response = await _dio.post(
        '/readers',
        data: {
          'fullName': reader.fullName,
          'email': reader.email,
          'phone': reader.phone,
        },
      );

      return Reader.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<Reader> update(Reader reader) {
    return guard(() async {
      final response = await _dio.put(
        '/readers/${reader.id}',
        data: {
          'fullName': reader.fullName,
          'email': reader.email,
          'phone': reader.phone,
        },
      );

      return Reader.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<void> delete(int id) {
    return guard(() async {
      await _dio.delete('readers/$id');
    });
  }

  @override
  Future<int> deleteMany(List<int> ids) {
    return guard(() async {
      final response = await _dio.post(
        '/readers/bulk-delete',
        data: {'ids': ids},
      );

      final data = response.data as Map<String, dynamic>;

      return data['deleted'] as int;
    });
  }

  @override
  Future<void> restore(int id) {
    return guard(() async {
      await _dio.post('readers/$id/restore');
    });
  }

  @override
  Future<void> hardDelete(int id) {
    return guard(() async {
      await _dio.delete('readers/$id', queryParameters: {'hard': true});
    });
  }
}
