import 'dart:async';

import '../models/person.dart';
import '../models/person_query.dart';
import '../repositories/person_repository.dart';
import 'entity_list_notifier.dart';

class PersonListNotifier
    extends EntityListNotifier<Person, PersonQuery> {
  PersonListNotifier(this._repository)
      : super(
    find: _repository.find,
    deleteMany: _repository.deleteMany,
    restore: _repository.restore,
    hardDelete: _repository.hardDelete,
    initialQuery: const PersonQuery(),
  );

  final PersonRepository _repository;

  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> setQuery(PersonQuery value) {
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

  Future<void> setBirthYearFrom(int? year) {
    return applyQuery(
      query.copyWith(
        birthYearFrom: year,
        page: 1,
      ),
    );
  }

  Future<void> setBirthYearTo(int? year) {
    return applyQuery(
      query.copyWith(
        birthYearTo: year,
        page: 1,
      ),
    );
  }

  Future<void> setCountry(String? countryId) {
    return applyQuery(
      query.copyWith(
        countryId: countryId,
        page: 1,
      ),
    );
  }

  Future<void> resetFilters() {
    return applyQuery(
      PersonQuery(size: query.size),
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

  Future<void> createPerson(Person person) async {
    await _repository.create(person);
    await load();
  }

  Future<void> updatePerson(Person person) async {
    await _repository.update(person);
    await load();
  }

  Future<void> deletePerson(String id) async {
    await _repository.softDelete(id);
    await load();
  }

  Future<Person?> findById(String id) {
    return _repository.findById(id);
  }

  String urlFor(PersonQuery value) {
    final params = <String, String>{
      if (value.search.isNotEmpty)
        'search': value.search,
      if (value.birthYearFrom != null)
        'birthYearFrom': '${value.birthYearFrom}',
      if (value.birthYearTo != null)
        'birthYearTo': '${value.birthYearTo}',
      if (value.countryId != null)
        'countryId': value.countryId!,
      'sort':
      '${value.sortField},${value.sortAscending ? 'asc' : 'desc'}',
      'page': '${value.page}',
      'size': '${value.size}',
      if (value.includeDeleted)
        'deleted': 'true',
    };

    return Uri(
      path: '/persons',
      queryParameters: params,
    ).toString();
  }
}