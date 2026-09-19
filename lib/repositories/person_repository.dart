import 'package:dio/dio.dart';

import '../models/person.dart';
import '../models/person_query.dart';
import '../models/page_result.dart';

abstract interface class PersonRepository {
  Future<PageResult<Person>> find(
      PersonQuery query, {
        CancelToken? cancelToken,
      });

  Future<Person?> findById(String id);

  Future<Person?> create(Person person);

  Future<Person?> update(Person person);

  Future<void> softDelete(String id);

  Future<void> hardDelete(String id);

  Future<void> restore(String id);

  Future<int> deleteMany(List<String> ids);
}