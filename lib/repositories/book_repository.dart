import 'package:up04_01_flutter_web/models/book.dart';
import 'package:up04_01_flutter_web/models/book_query.dart';
import 'package:up04_01_flutter_web/models/page_result.dart';
import 'package:dio/dio.dart';

abstract interface class BookRepository {
  Future<PageResult<Book>> find(BookQuery query, {CancelToken? cancelToken});

  Future<Book?> findById(int id);

  Future<Book?> create(Book book);

  Future<Book?> update(Book book);

  Future<void> softDelete(int id);

  Future<void> hardDelete(int id);

  Future<void> restore(int id);

  Future<int> deleteMany(List<int> ids);
}
