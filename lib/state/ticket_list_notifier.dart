import 'dart:async';

import '../models/ticket.dart';
import '../models/ticket_query.dart';
import '../repositories/ticket_repository.dart';
import 'entity_list_notifier.dart';

class TicketListNotifier
    extends EntityListNotifier<Ticket, TicketQuery> {
  TicketListNotifier(this._repository)
      : super(
    find: _repository.find,
    deleteMany: _repository.deleteMany,
    restore: _repository.restore,
    hardDelete: _repository.hardDelete,
    initialQuery: const TicketQuery(),
  );

  final TicketRepository _repository;

  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> setQuery(TicketQuery value) {
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

  Future<void> setBooking(String? bookingId) {
    return applyQuery(
      query.copyWith(
        bookingId: bookingId,
        page: 1,
      ),
    );
  }

  Future<void> resetFilters() {
    return applyQuery(
      TicketQuery(size: query.size),
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

  Future<void> createTicket(Ticket ticket) async {
    await _repository.create(ticket);
    await load();
  }

  Future<void> updateTicket(Ticket ticket) async {
    await _repository.update(ticket);
    await load();
  }

  Future<void> deleteTicket(String id) async {
    await _repository.softDelete(id);
    await load();
  }

  Future<Ticket?> findById(String id) {
    return _repository.findById(id);
  }

  String urlFor(TicketQuery value) {
    final params = <String, String>{
      if (value.search.isNotEmpty)
        'search': value.search,
      if (value.bookingId != null)
        'bookingId': value.bookingId!,
      'sort':
      '${value.sortField},${value.sortAscending ? 'asc' : 'desc'}',
      'page': '${value.page}',
      'size': '${value.size}',
      if (value.includeDeleted)
        'deleted': 'true',
    };

    return Uri(
      path: '/tickets',
      queryParameters: params,
    ).toString();
  }
}