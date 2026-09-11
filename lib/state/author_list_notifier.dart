import 'dart:async';

import '../models/author.dart';
import '../models/author_query.dart';
import '../repositories/author_repository.dart';
import 'entity_list_notifier.dart';

class AuthorListNotifier extends EntityListNotifier<Author, AuthorQuery> {
  AuthorListNotifier(this._repository)
    : super(
        find: _repository.find,
        deleteMany: _repository.deleteMany,
        restore: _repository.restore,
        hardDelete: _repository.hardDelete,
        initialQuery: const AuthorQuery(),
      );

  final AuthorRepository _repository;

  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> setQuery(AuthorQuery value) {
    return applyQuery(value);
  }

  void search(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      applyQuery(query.copyWith(search: value.trim(), page: 1));
    });
  }

  Future<void> clearSearch() {
    _searchDebounce?.cancel();

    return applyQuery(query.copyWith(search: '', page: 1));
  }

  Future<void> sort(String field) {
    final sameField = query.sortField == field;

    return applyQuery(
      query.copyWith(
        sortField: field,
        sortAscending: sameField ? !query.sortAscending : true,
        page: 1,
      ),
    );
  }

  Future<void> firstPage() {
    return applyQuery(query.copyWith(page: 1));
  }

  Future<void> previousPage() {
    return applyQuery(query.copyWith(page: query.page - 1));
  }

  Future<void> nextPage() {
    return applyQuery(query.copyWith(page: query.page + 1));
  }

  Future<void> lastPage() {
    return applyQuery(query.copyWith(page: result.totalPages));
  }

  Future<void> changePageSize(int size) {
    return applyQuery(query.copyWith(page: 1, size: size));
  }

  Future<void> setIncludeDeleted(bool value) {
    return applyQuery(query.copyWith(includeDeleted: value, page: 1));
  }

  Future<void> createAuthor(Author author) async {
    await _repository.create(author);
    await load();
  }

  Future<void> updateAuthor(Author author) async {
    await _repository.update(author);
    await load();
  }

  Future<void> deleteAuthor(int id) async {
    await _repository.softDelete(id);
    await load();
  }

  Future<Author?> findById(int id) {
    return _repository.findById(id);
  }

  String urlFor(AuthorQuery value) {
    final params = <String, String>{
      if (value.search.isNotEmpty) 'search': value.search,
      'sort': '${value.sortField},${value.sortAscending ? 'asc' : 'desc'}',
      'page': '${value.page}',
      'size': '${value.size}',
      if (value.includeDeleted) 'deleted': 'true',
    };

    return Uri(path: '/authors', queryParameters: params).toString();
  }
}
