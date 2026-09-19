class SessionQuery {
  final String search;
  final String? movieId;
  final String? hallId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const SessionQuery({
    this.search = '',
    this.movieId,
    this.hallId,
    this.dateFrom,
    this.dateTo,
    this.sortField = 'date',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  SessionQuery copyWith({
    String? search,
    Object? movieId = _unset,
    Object? hallId = _unset,
    Object? dateFrom = _unset,
    Object? dateTo = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return SessionQuery(
      search: search ?? this.search,
      movieId: movieId == _unset ? this.movieId : movieId as String?,
      hallId: hallId == _unset ? this.hallId : hallId as String?,
      dateFrom: dateFrom == _unset ? this.dateFrom : dateFrom as DateTime?,
      dateTo: dateTo == _unset ? this.dateTo : dateTo as DateTime?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? this.page,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  static const _unset = Object();
}