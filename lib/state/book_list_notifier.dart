import 'dart:async';

import '../models/book.dart';
import '../models/book_query.dart';
import '../repositories/book_repository.dart';
import 'entity_list_notifier.dart';

class BookListNotifier
    extends EntityListNotifier<Book, BookQuery> {
  BookListNotifier(this._repository)
      : super(
    find: _repository.find,
    deleteMany: _repository.deleteMany,
    restore: _repository.restore,
    hardDelete: _repository.hardDelete,
    initialQuery: const BookQuery(),
  );

  final BookRepository _repository;

  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> setQuery(BookQuery value) {
    return applyQuery(value);
  }

  void search(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
          () {
        applyQuery(
          query.copyWith(
            search: value.trim(),
            page: 1,
          ),
        );
      },
    );
  }

  Future<void> clearSearch() {
    _searchDebounce?.cancel();

    return applyQuery(
      query.copyWith(
        search: '',
        page: 1,
      ),
    );
  }

  Future<void> sort(String field) {
    final sameField = query.sortField == field;

    return applyQuery(
      query.copyWith(
        sortField: field,
        sortAscending: sameField
            ? !query.sortAscending
            : true,
        page: 1,
      ),
    );
  }

  Future<void> setGenre(int? id) {
    return applyQuery(
      query.copyWith(
        genreId: id,
        page: 1,
      ),
    );
  }

  Future<void> setPublisher(int? id) {
    return applyQuery(
      query.copyWith(
        publisherId: id,
        page: 1,
      ),
    );
  }

  Future<void> setYearFrom(int? year) {
    return applyQuery(
      query.copyWith(
        yearFrom: year,
        page: 1,
      ),
    );
  }

  Future<void> setYearTo(int? year) {
    return applyQuery(
      query.copyWith(
        yearTo: year,
        page: 1,
      ),
    );
  }

  Future<void> resetFilters() {
    return applyQuery(
      BookQuery(
        size: query.size,
      ),
    );
  }

  Future<void> firstPage() {
    return applyQuery(query.copyWith(page: 1));
  }

  Future<void> previousPage() {
    return applyQuery(
      query.copyWith(page: query.page - 1),
    );
  }

  Future<void> nextPage() {
    return applyQuery(
      query.copyWith(page: query.page + 1),
    );
  }

  Future<void> lastPage() {
    return applyQuery(
      query.copyWith(page: result.totalPages),
    );
  }

  Future<void> changePageSize(int size) {
    return applyQuery(
      query.copyWith(
        page: 1,
        size: size,
      ),
    );
  }

  Future<void> setIncludeDeleted(bool value) {
    return applyQuery(
      query.copyWith(
        includeDeleted: value,
        page: 1,
      ),
    );
  }

  Future<void> createBook(Book book) async {
    await _repository.create(book);
    await load();
  }

  Future<void> updateBook(Book book) async {
    await _repository.update(book);
    await load();
  }

  Future<void> deleteBook(int id) async {
    await _repository.softDelete(id);
    await load();
  }

  Future<Book?> findById(int id) {
    return _repository.findById(id);
  }

  String urlFor(BookQuery value) {
    final params = <String, String>{
      if (value.search.isNotEmpty)
        'search': value.search,
      if (value.genreId != null)
        'genreId': '${value.genreId}',
      if (value.publisherId != null)
        'publisherId': '${value.publisherId}',
      if (value.yearFrom != null)
        'yearFrom': '${value.yearFrom}',
      if (value.yearTo != null)
        'yearTo': '${value.yearTo}',
      'sort':
      '${value.sortField},${value.sortAscending ? 'asc' : 'desc'}',
      'page': '${value.page}',
      'size': '${value.size}',
      if (value.includeDeleted)
        'deleted': 'true',
    };

    return Uri(
      path: '/books',
      queryParameters: params,
    ).toString();
  }
}