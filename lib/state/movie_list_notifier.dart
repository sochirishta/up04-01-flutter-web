import 'dart:async';

import '../models/movie.dart';
import '../models/movie_query.dart';
import '../repositories/movie_repository.dart';
import 'entity_list_notifier.dart';

class MovieListNotifier extends EntityListNotifier<Movie, MovieQuery> {
  MovieListNotifier(this._repository)
      : super(
    find: _repository.find,
    deleteMany: _repository.deleteMany,
    restore: _repository.restore,
    hardDelete: _repository.hardDelete,
    initialQuery: const MovieQuery(),
  );

  final MovieRepository _repository;

  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> setQuery(MovieQuery value) {
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
        sortAscending:
        sameField ? !query.sortAscending : true,
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

  Future<void> setDurationFrom(int? duration) {
    return applyQuery(
      query.copyWith(
        durationFrom: duration,
        page: 1,
      ),
    );
  }

  Future<void> setDurationTo(int? duration) {
    return applyQuery(
      query.copyWith(
        durationTo: duration,
        page: 1,
      ),
    );
  }

  Future<void> setGenre(String? genreId) {
    return applyQuery(
      query.copyWith(
        genreId: genreId,
        page: 1,
      ),
    );
  }

  Future<void> setPerson(String? personId) {
    return applyQuery(
      query.copyWith(
        personId: personId,
        page: 1,
      ),
    );
  }

  Future<void> resetFilters() {
    return applyQuery(
      MovieQuery(size: query.size),
    );
  }

  Future<void> firstPage() {
    return applyQuery(
      query.copyWith(page: 1),
    );
  }

  Future<void> previousPage() {
    if (query.page <= 1) {
      return Future.value();
    }

    return applyQuery(
      query.copyWith(page: query.page - 1),
    );
  }

  Future<void> nextPage() {
    if (!result.hasNext) {
      return Future.value();
    }

    return applyQuery(
      query.copyWith(page: query.page + 1),
    );
  }

  Future<void> lastPage() {
    return applyQuery(
      query.copyWith(
        page: result.totalPages,
      ),
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

  Future<void> createMovie(Movie movie) async {
    await _repository.create(movie);
    await load();
  }

  Future<void> updateMovie(Movie movie) async {
    await _repository.update(movie);
    await load();
  }

  Future<void> deleteMovie(String id) async {
    await _repository.softDelete(id);
    await load();
  }

  Future<Movie?> findById(String id) {
    return _repository.findById(id);
  }

  String urlFor(MovieQuery value) {
    final params = <String, String>{
      if (value.search.isNotEmpty)
        'search': value.search,
      if (value.yearFrom != null)
        'yearFrom': '${value.yearFrom}',
      if (value.yearTo != null)
        'yearTo': '${value.yearTo}',
      if (value.durationFrom != null)
        'durationFrom': '${value.durationFrom}',
      if (value.durationTo != null)
        'durationTo': '${value.durationTo}',
      if (value.genreId != null && value.genreId!.isNotEmpty)
        'genreId': value.genreId!,
      if (value.personId != null && value.personId!.isNotEmpty)
        'personId': value.personId!,
      'sort':
      '${value.sortField},${value.sortAscending ? 'asc' : 'desc'}',
      'page': '${value.page}',
      'size': '${value.size}',
      if (value.includeDeleted)
        'deleted': 'true',
    };

    return Uri(
      path: '/movies',
      queryParameters: params,
    ).toString();
  }
}