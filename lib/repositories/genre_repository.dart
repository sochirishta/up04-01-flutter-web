import 'package:dio/dio.dart';

import '../models/genre.dart';
import '../models/genre_query.dart';
import '../models/page_result.dart';

abstract interface class GenreRepository {
  Future<PageResult<Genre>> find(
      GenreQuery query, {
        CancelToken? cancelToken,
      });

  Future<Genre?> findById(String id);

  Future<Genre?> create(Genre genre);

  Future<Genre?> update(Genre genre);

  Future<void> softDelete(String id);

  Future<void> hardDelete(String id);

  Future<void> restore(String id);

  Future<int> deleteMany(List<String> ids);
}