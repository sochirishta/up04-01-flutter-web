import '../models/page_result.dart';
import '../models/reader.dart';
import '../models/reader_query.dart';
import 'package:dio/dio.dart';

abstract interface class ReaderRepository {
  Future<PageResult<Reader>> find(
    ReaderQuery query, {
    CancelToken? cancelToken,
  });

  Future<Reader?> findById(int id);

  Future<Reader> create(Reader reader);

  Future<Reader> update(Reader reader);

  Future<void> delete(int id);

  Future<int> deleteMany(List<int> ids);

  Future<void> restore(int id);

  Future<void> hardDelete(int id);
}
