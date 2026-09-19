import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/page_result.dart';
import '../models/person.dart';
import '../models/person_query.dart';
import 'person_repository.dart';

class ApiPersonRepository implements PersonRepository {
  final Dio _dio;

  ApiPersonRepository(this._dio);

  @override
  Future<PageResult<Person>> find(
      PersonQuery q, {
        CancelToken? cancelToken,
      }) {
    return guard(() async {
      final filters = <String>[];

      if (q.search.trim().isNotEmpty) {
        final value = q.search.trim().replaceAll('"', r'\"');
        filters.add('fullName ~ "$value"');
      }

      if (q.birthYearFrom != null) {
        filters.add('birthYear >= ${q.birthYearFrom}');
      }

      if (q.birthYearTo != null) {
        filters.add('birthYear <= ${q.birthYearTo}');
      }

      if (q.countryId != null && q.countryId!.isNotEmpty) {
        filters.add('country = "${q.countryId}"');
      }

      if (!q.includeDeleted) {
        filters.add('deletedAt = ""');
      }

      final response = await _dio.get(
        '/collections/persons/records',
        queryParameters: {
          'page': q.page,
          'perPage': q.size,
          'sort': '${q.sortAscending ? '+' : '-'}${q.sortField}',
          if (filters.isNotEmpty) 'filter': filters.join(' && '),
          'expand': 'country',
        },
        cancelToken: cancelToken,
      );

      return _pageResult(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<Person?> findById(String id) {
    return guard(() async {
      final response = await _dio.get(
        '/collections/persons/records/$id',
        queryParameters: {
          'expand': 'country',
        },
      );

      return Person.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  @override
  Future<Person?> create(Person person) {
    return guard(() async {
      final response = await _dio.post(
        '/collections/persons/records',
        data: {
          'fullName': person.fullName,
          'birthYear': person.birthYear,
          'country': person.countryId,
          'deletedAt': '',
        },
      );

      return Person.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  @override
  Future<Person?> update(Person person) {
    return guard(() async {
      final response = await _dio.patch(
        '/collections/persons/records/${person.id}',
        data: {
          'fullName': person.fullName,
          'birthYear': person.birthYear,
          'country': person.countryId,
        },
      );

      return Person.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  @override
  Future<void> softDelete(String id) {
    return guard(() async {
      await _dio.patch(
        '/collections/persons/records/$id',
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
        '/collections/persons/records/$id',
      );
    });
  }

  @override
  Future<void> restore(String id) {
    return guard(() async {
      await _dio.patch(
        '/collections/persons/records/$id',
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

  PageResult<Person> _pageResult(Map<String, dynamic> data) {
    final items = (data['items'] as List<dynamic>)
        .map(
          (item) => Person.fromJson(
        item as Map<String, dynamic>,
      ),
    )
        .toList();

    return PageResult<Person>(
      items: items,
      page: (data['page'] as num).toInt(),
      size: (data['perPage'] as num).toInt(),
      total: (data['totalItems'] as num).toInt(),
    );
  }
}