import 'dart:async';

import '../models/hall.dart';
import '../models/hall_query.dart';
import '../repositories/hall_repository.dart';
import 'entity_list_notifier.dart';

class HallListNotifier
    extends EntityListNotifier<Hall, HallQuery> {
  HallListNotifier(this._repository)
      : super(
    find: _repository.find,
    deleteMany: _repository.deleteMany,
    restore: _repository.restore,
    hardDelete: _repository.hardDelete,
    initialQuery: const HallQuery(),
  );

  final HallRepository _repository;

  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> setQuery(HallQuery value) {
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

  Future<void> setCapacityFrom(int? value) {
    return applyQuery(
      query.copyWith(
        capacityFrom: value,
        page: 1,
      ),
    );
  }

  Future<void> setCapacityTo(int? value) {
    return applyQuery(
      query.copyWith(
        capacityTo: value,
        page: 1,
      ),
    );
  }

  Future<void> resetFilters() {
    return applyQuery(
      HallQuery(size: query.size),
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

  Future<void> createHall(Hall hall) async {
    await _repository.create(hall);
    await load();
  }

  Future<void> updateHall(Hall hall) async {
    await _repository.update(hall);
    await load();
  }

  Future<void> deleteHall(String id) async {
    await _repository.softDelete(id);
    await load();
  }

  Future<Hall?> findById(String id) {
    return _repository.findById(id);
  }

  String urlFor(HallQuery value) {
    final params = <String, String>{
      if (value.search.isNotEmpty)
        'search': value.search,
      if (value.capacityFrom != null)
        'capacityFrom': '${value.capacityFrom}',
      if (value.capacityTo != null)
        'capacityTo': '${value.capacityTo}',
      'sort':
      '${value.sortField},${value.sortAscending ? 'asc' : 'desc'}',
      'page': '${value.page}',
      'size': '${value.size}',
      if (value.includeDeleted)
        'deleted': 'true',
    };

    return Uri(
      path: '/halls',
      queryParameters: params,
    ).toString();
  }
}