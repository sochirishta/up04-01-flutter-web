import 'package:dio/dio.dart';

import '../models/movie.dart';
import '../models/movie_query.dart';
import '../models/page_result.dart';

abstract interface class MovieRepository {
  Future<PageResult<Movie>> find(
      MovieQuery query, {
        CancelToken? cancelToken,
      });

  Future<Movie?> findById(String id);

  Future<Movie?> create(Movie movie);

  Future<Movie?> update(Movie movie);

  Future<void> softDelete(String id);

  Future<void> hardDelete(String id);

  Future<void> restore(String id);

  Future<int> deleteMany(List<String> ids);
}