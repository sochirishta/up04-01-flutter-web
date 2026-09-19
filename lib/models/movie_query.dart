class MovieQuery {
  final String search;
  final int? yearFrom;
  final int? yearTo;
  final int? durationFrom;
  final int? durationTo;
  final String? genreId;
  final String? personId;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const MovieQuery({
    this.search = '',
    this.yearFrom,
    this.yearTo,
    this.durationFrom,
    this.durationTo,
    this.genreId,
    this.personId,
    this.sortField = 'title',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  MovieQuery copyWith({
    String? search,
    Object? yearFrom = _unset,
    Object? yearTo = _unset,
    Object? durationFrom = _unset,
    Object? durationTo = _unset,
    Object? genreId = _unset,
    Object? personId = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return MovieQuery(
      search: search ?? this.search,
      yearFrom: yearFrom == _unset ? this.yearFrom : yearFrom as int?,
      yearTo: yearTo == _unset ? this.yearTo : yearTo as int?,
      durationFrom: durationFrom == _unset
          ? this.durationFrom
          : durationFrom as int?,
      durationTo: durationTo == _unset
          ? this.durationTo
          : durationTo as int?,
      genreId: genreId == _unset
          ? this.genreId
          : genreId as String?,
      personId: personId == _unset
          ? this.personId
          : personId as String?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? this.page,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  static const _unset = Object();
}