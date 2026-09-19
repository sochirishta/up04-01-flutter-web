import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/country.dart';
import '../models/country_query.dart';
import '../models/page_result.dart';
import 'country_repository.dart';

class ApiCountryRepository implements CountryRepository {
  final Dio _dio;

  ApiCountryRepository(this._dio);

  @override
  Future<PageResult<Country>> find(
      CountryQuery q, {
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
        '/collections/countries/records',
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
  Future<Country?> findById(String id) {
    return guard(() async {
      final response = await _dio.get(
        '/collections/countries/records/$id',
      );

      return Country.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  @override
  Future<Country?> create(Country country) {
    return guard(() async {
      final response = await _dio.post(
        '/collections/countries/records',
        data: {
          'name': country.name,
          'deletedAt': '',
        },
      );

      return Country.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  @override
  Future<Country?> update(Country country) {
    return guard(() async {
      final response = await _dio.patch(
        '/collections/countries/records/${country.id}',
        data: {
          'name': country.name,
        },
      );

      return Country.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  @override
  Future<void> softDelete(String id) {
    return guard(() async {
      await _dio.patch(
        '/collections/countries/records/$id',
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
        '/collections/countries/records/$id',
      );
    });
  }

  @override
  Future<void> restore(String id) {
    return guard(() async {
      await _dio.patch(
        '/collections/countries/records/$id',
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

  PageResult<Country> _pageResult(Map<String, dynamic> data) {
    final items = (data['items'] as List<dynamic>)
        .map(
          (item) => Country.fromJson(
        item as Map<String, dynamic>,
      ),
    )
        .toList();

    return PageResult<Country>(
      items: items,
      page: (data['page'] as num).toInt(),
      size: (data['perPage'] as num).toInt(),
      total: (data['totalItems'] as num).toInt(),
    );
  }
}