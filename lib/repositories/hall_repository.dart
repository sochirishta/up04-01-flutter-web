import 'package:dio/dio.dart';

import '../models/hall.dart';
import '../models/hall_query.dart';
import '../models/page_result.dart';

abstract interface class HallRepository {
  Future<PageResult<Hall>> find(
      HallQuery query, {
        CancelToken? cancelToken,
      });

  Future<Hall?> findById(String id);

  Future<Hall?> create(Hall hall);

  Future<Hall?> update(Hall hall);

  Future<void> softDelete(String id);

  Future<void> hardDelete(String id);

  Future<void> restore(String id);

  Future<int> deleteMany(List<String> ids);
}