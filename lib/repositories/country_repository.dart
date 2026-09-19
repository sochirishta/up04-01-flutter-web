import 'package:dio/dio.dart';

import '../models/country.dart';
import '../models/country_query.dart';
import '../models/page_result.dart';

abstract interface class CountryRepository {
  Future<PageResult<Country>> find(
      CountryQuery query, {
        CancelToken? cancelToken,
      });

  Future<Country?> findById(String id);

  Future<Country?> create(Country country);

  Future<Country?> update(Country country);

  Future<void> softDelete(String id);

  Future<void> hardDelete(String id);

  Future<void> restore(String id);

  Future<int> deleteMany(List<String> ids);
}