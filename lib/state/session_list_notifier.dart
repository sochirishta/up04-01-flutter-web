import 'dart:async';

import '../models/session.dart';
import '../models/session_query.dart';
import '../repositories/session_repository.dart';
import 'entity_list_notifier.dart';

class SessionListNotifier
    extends EntityListNotifier<CinemaSession, SessionQuery> {
  SessionListNotifier(this._repository)
      : super(
    find: _repository.find,
    deleteMany: _repository.deleteMany,
    restore: _repository.restore,
    hardDelete: _repository.hardDelete,
    initialQuery: const SessionQuery(),
  );

  final SessionRepository _repository;

  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> setQuery(SessionQuery value) {
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

  Future<void> setMovie(String? movieId) {
    return applyQuery(
      query.copyWith(
        movieId: movieId,
        page: 1,
      ),
    );
  }

  Future<void> setHall(String? hallId) {
    return applyQuery(
      query.copyWith(
        hallId: hallId,
        page: 1,
      ),
    );
  }

  Future<void> setDateFrom(DateTime? value) {
    return applyQuery(
      query.copyWith(
        dateFrom: value,
        page: 1,
      ),
    );
  }

  Future<void> setDateTo(DateTime? value) {
    return applyQuery(
      query.copyWith(
        dateTo: value,
        page: 1,
      ),
    );
  }

  Future<void> resetFilters() {
    return applyQuery(
      SessionQuery(size: query.size),
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

  Future<void> createSession(CinemaSession session) async {
    await _repository.create(session);
    await load();
  }

  Future<void> updateSession(CinemaSession session) async {
    await _repository.update(session);
    await load();
  }

  Future<void> deleteSession(String id) async {
    await _repository.softDelete(id);
    await load();
  }

  Future<CinemaSession?> findById(String id) {
    return _repository.findById(id);
  }

  String urlFor(SessionQuery value) {
    final params = <String, String>{
      if (value.search.isNotEmpty)
        'search': value.search,
      if (value.movieId != null)
        'movieId': value.movieId!,
      if (value.hallId != null)
        'hallId': value.hallId!,
      if (value.dateFrom != null)
        'dateFrom': value.dateFrom!.toIso8601String(),
      if (value.dateTo != null)
        'dateTo': value.dateTo!.toIso8601String(),
      'sort':
      '${value.sortField},${value.sortAscending ? 'asc' : 'desc'}',
      'page': '${value.page}',
      'size': '${value.size}',
      if (value.includeDeleted)
        'deleted': 'true',
    };

    return Uri(
      path: '/sessions',
      queryParameters: params,
    ).toString();
  }
}