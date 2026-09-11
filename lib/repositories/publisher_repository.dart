import '../models/page_result.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';
import 'package:dio/dio.dart';

abstract class PublisherRepository {
  Future<PageResult<Publisher>> find(
    PublisherQuery query, {
    CancelToken? cancelToken,
  });

  Future<Publisher?> findById(int id);

  Future<Publisher> create(Publisher publisher);

  Future<Publisher> update(Publisher publisher);

  Future<void> delete(int id);

  Future<int> deleteMany(List<int> ids);

  Future<void> restore(int id);

  Future<void> hardDelete(int id);
}
