import 'package:up04_01_flutter_web/models/book_query.dart';
import 'package:up04_01_flutter_web/models/page_result.dart';
import 'package:up04_01_flutter_web/repositories/book_repository.dart';
import 'package:up04_01_flutter_web/models/book.dart';
import '../core/api_exceptions.dart';
import 'package:dio/dio.dart';

class ApiBookRepository implements BookRepository {
  final Dio _dio;

  ApiBookRepository(this._dio);

  @override
  Future<PageResult<Book>> find(BookQuery q, {CancelToken? cancelToken}) {
    return guard(() async {
      final response = await _dio.get(
        '/books',
        queryParameters: {
          if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
          if (q.genreId != null) 'genreId': q.genreId,
          if (q.publisherId != null) 'publisherId': q.publisherId,
          if (q.authorId != null) 'authorId': q.authorId,
          if (q.yearFrom != null) 'yearFrom': q.yearFrom,
          if (q.yearTo != null) 'yearTo': q.yearTo,
          if (q.available != null) 'available': q.available,
          'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
          'page': q.page,
          'size': q.size,
          if (q.includeDeleted) 'includeDeleted': true,
        },
        cancelToken: cancelToken,
      );
      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List)
          .map((item) => Book.fromJson(item as Map<String, dynamic>))
          .toList();
      return PageResult<Book>(
        items: items,
        page: data['page'] as int,
        size: data['size'] as int,
        total: data['total'] as int,
      );
    });
  }

  @override
  Future<Book?> findById(int id) {
    return guard(() async {
      final response = await _dio.get('/books/$id');
      return Book.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<Book?> create(Book book) {
    return guard(() async {
      final response = await _dio.post(
        '/books',
        data: {
          'title': book.title,
          'isbn': book.isbn,
          'year': book.year,
          'pages': book.pages,
          'publisherId': book.publisherId,
          'authorIds': book.authorIds,
          'genreIds': book.genreIds,
          'copiesTotal': book.copiesTotal,
        },
      );

      return Book.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<Book?> update(Book book) {
    return guard(() async {
      final response = await _dio.put(
        '/books/${book.id}',
        data: {
          'title': book.title,
          'isbn': book.isbn,
          'year': book.year,
          'pages': book.pages,
          'publisherId': book.publisherId,
          'authorIds': book.authorIds,
          'genreIds': book.genreIds,
          'copiesTotal': book.copiesTotal,
        },
      );
      return Book.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<void> softDelete(int id) {
    return guard(() async {
      await _dio.delete('books/$id');
    });
  }

  @override
  Future<void> hardDelete(int id) {
    return guard(() async {
      await _dio.delete('books/$id', queryParameters: {'hard': true});
    });
  }

  @override
  Future<void> restore(int id) {
    return guard(() async {
      await _dio.post('books/$id/restore');
    });
  }

  @override
  Future<int> deleteMany(List<int> ids) {
    return guard(() async {
      final response = await _dio.post(
        '/books/bulk-delete',
        data: {'ids': ids},
      );
      final data = response.data as Map<String, dynamic>;
      return data['deleted'] as int;
    });
  }
}
