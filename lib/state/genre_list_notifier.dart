import 'dart:async';

import '../models/genre.dart';
import '../models/genre_query.dart';
import '../repositories/genre_repository.dart';
import 'entity_list_notifier.dart';

class GenreListNotifier extends EntityListNotifier<Genre, GenreQuery> {
  GenreListNotifier(this._repository)
    : super(
        find: _repository.find,
        deleteMany: _repository.deleteMany,
        restore: _repository.restore,
        hardDelete: _repository.hardDelete,
        initialQuery: const GenreQuery(),
      );

  final GenreRepository _repository;

  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> setQuery(GenreQuery value) {
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

  Future<void> createGenre(Genre genre) async {
    await _repository.create(genre);
    await load();
  }

  Future<void> updateGenre(Genre genre) async {
    await _repository.update(genre);
    await load();
  }

  Future<void> deleteGenre(int id) async {
    await _repository.delete(id);
    await load();
  }

  Future<Genre?> findById(int id) {
    return _repository.findById(id);
  }

  String urlFor(GenreQuery value) {
    final params = <String, String>{
      if (value.search.isNotEmpty) 'search': value.search,
      'sort': '${value.sortField},${value.sortAscending ? 'asc' : 'desc'}',
      'page': '${value.page}',
      'size': '${value.size}',
      if (value.includeDeleted) 'deleted': 'true',
    };

    return Uri(path: '/genres', queryParameters: params).toString();
  }
}
