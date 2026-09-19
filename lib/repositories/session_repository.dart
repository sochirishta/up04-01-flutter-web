import 'package:dio/dio.dart';

import '../models/page_result.dart';
import '../models/session.dart';
import '../models/session_query.dart';

abstract interface class SessionRepository {
  Future<PageResult<CinemaSession>> find(
      SessionQuery query, {
        CancelToken? cancelToken,
      });

  Future<CinemaSession?> findById(String id);

  Future<CinemaSession?> create(CinemaSession session);

  Future<CinemaSession?> update(CinemaSession session);

  Future<void> softDelete(String id);

  Future<void> hardDelete(String id);

  Future<void> restore(String id);

  Future<int> deleteMany(List<String> ids);
}