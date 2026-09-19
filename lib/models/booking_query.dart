class BookingQuery {
  final String search;
  final String? sessionId;
  final String? userId;
  final int? row;
  final int? seat;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const BookingQuery({
    this.search = '',
    this.sessionId,
    this.userId,
    this.row,
    this.seat,
    this.sortField = 'id',
    this.sortAscending = false,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  BookingQuery copyWith({
    String? search,
    Object? sessionId = _unset,
    Object? userId = _unset,
    Object? row = _unset,
    Object? seat = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return BookingQuery(
      search: search ?? this.search,
      sessionId: sessionId == _unset
          ? this.sessionId
          : sessionId as String?,
      userId: userId == _unset
          ? this.userId
          : userId as String?,
      row: row == _unset ? this.row : row as int?,
      seat: seat == _unset ? this.seat : seat as int?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? this.page,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  static const _unset = Object();
}