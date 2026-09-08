class LoanQuery {
  final String search;
  final String? status;
  final int? readerId;
  final int? bookId;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;

  const LoanQuery({
    this.search = '',
    this.status,
    this.readerId,
    this.bookId,
    this.sortField = 'issuedAt',
    this.sortAscending = false,
    this.page = 1,
    this.size = 10,
  });

  LoanQuery copyWith({
    String? search,
    Object? status = _unset,
    Object? readerId = _unset,
    Object? bookId = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
  }) {
    return LoanQuery(
      search: search ?? this.search,
      status: status == _unset ? this.status : status as String?,
      readerId:
      readerId == _unset ? this.readerId : readerId as int?,
      bookId: bookId == _unset ? this.bookId : bookId as int?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? this.page,
      size: size ?? this.size,
    );
  }

  static const _unset = Object();
}