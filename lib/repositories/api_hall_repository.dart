import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/hall.dart';
import '../models/hall_query.dart';
import '../models/page_result.dart';
import 'hall_repository.dart';

class ApiHallRepository implements HallRepository {
  final Dio _dio;

  ApiHallRepository(this._dio);

  @override
  Future<PageResult<Hall>> find(
      HallQuery q, {
        CancelToken? cancelToken,
      }) {
    return guard(() async {
      final filters = <String>[];

      if (q.search.trim().isNotEmpty) {
        final value = q.search.trim().replaceAll('"', r'\"');
        filters.add('name ~ "$value"');
      }

      if (q.capacityFrom != null) {
        filters.add('capacity >= ${q.capacityFrom}');
      }

      if (q.capacityTo != null) {
        filters.add('capacity <= ${q.capacityTo}');
      }

      if (!q.includeDeleted) {
        filters.add('deletedAt = ""');
      }

      final response = await _dio.get(
        '/collections/halls/records',
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
  Future<Hall?> findById(String id) {
    return guard(() async {
      final response = await _dio.get(
        '/collections/halls/records/$id',
      );

      return Hall.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  @override
  Future<Hall?> create(Hall hall) {
    return guard(() async {
      final response = await _dio.post(
        '/collections/halls/records',
        data: {
          'name': hall.name,
          'capacity': hall.capacity,
          'deletedAt': '',
        },
      );

      return Hall.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  @override
  Future<Hall?> update(Hall hall) {
    return guard(() async {
      final response = await _dio.patch(
        '/collections/halls/records/${hall.id}',
        data: {
          'name': hall.name,
          'capacity': hall.capacity,
        },
      );

      return Hall.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  @override
  Future<void> softDelete(String id) {
    return guard(() async {
      await _dio.patch(
        '/collections/halls/records/$id',
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
        '/collections/halls/records/$id',
      );
    });
  }

  @override
  Future<void> restore(String id) {
    return guard(() async {
      await _dio.patch(
        '/collections/halls/records/$id',
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

  PageResult<Hall> _pageResult(Map<String, dynamic> data) {
    final items = (data['items'] as List<dynamic>)
        .map(
          (item) => Hall.fromJson(
        item as Map<String, dynamic>,
      ),
    )
        .toList();

    return PageResult<Hall>(
      items: items,
      page: (data['page'] as num).toInt(),
      size: (data['perPage'] as num).toInt(),
      total: (data['totalItems'] as num).toInt(),
    );
  }
}