import 'dart:async';

import '../models/reader.dart';
import '../models/reader_query.dart';
import '../repositories/reader_repository.dart';
import 'entity_list_notifier.dart';

class ReaderListNotifier
    extends EntityListNotifier<Reader, ReaderQuery> {
  ReaderListNotifier(this._repository)
      : super(
    find: _repository.find,
    deleteMany: _repository.deleteMany,
    restore: _repository.restore,
    hardDelete: _repository.hardDelete,
    initialQuery: const ReaderQuery(),
  );

  final ReaderRepository _repository;

  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> setQuery(ReaderQuery value) =>
      applyQuery(value);

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

  Future<void> firstPage() =>
      applyQuery(query.copyWith(page: 1));

  Future<void> previousPage() {
    if (query.page <= 1) return Future.value();

    return applyQuery(
      query.copyWith(page: query.page - 1),
    );
  }

  Future<void> nextPage() {
    if (!result.hasNext) return Future.value();

    return applyQuery(
      query.copyWith(page: query.page + 1),
    );
  }

  Future<void> lastPage() =>
      applyQuery(query.copyWith(page: result.totalPages));

  Future<void> changePageSize(int size) =>
      applyQuery(query.copyWith(page: 1, size: size));

  Future<void> setIncludeDeleted(bool value) =>
      applyQuery(
        query.copyWith(
          includeDeleted: value,
          page: 1,
        ),
      );

  Future<void> createReader(Reader reader) async {
    await _repository.create(reader);
    await load();
  }

  Future<void> updateReader(Reader reader) async {
    await _repository.update(reader);
    await load();
  }

  Future<void> deleteReader(int id) async {
    await _repository.delete(id);
    await load();
  }

  Future<Reader?> findById(int id) =>
      _repository.findById(id);
}