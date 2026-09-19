class TicketQuery {
  final String search;
  final String? bookingId;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const TicketQuery({
    this.search = '',
    this.bookingId,
    this.sortField = 'issuedAt',
    this.sortAscending = false,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  TicketQuery copyWith({
    String? search,
    Object? bookingId = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return TicketQuery(
      search: search ?? this.search,
      bookingId: bookingId == _unset
          ? this.bookingId
          : bookingId as String?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? this.page,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  static const _unset = Object();
}