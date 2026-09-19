class PersonQuery {
  final String search;
  final int? birthYearFrom;
  final int? birthYearTo;
  final String? countryId;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const PersonQuery({
    this.search = '',
    this.birthYearFrom,
    this.birthYearTo,
    this.countryId,
    this.sortField = 'fullName',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  PersonQuery copyWith({
    String? search,
    Object? birthYearFrom = _unset,
    Object? birthYearTo = _unset,
    Object? countryId = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return PersonQuery(
      search: search ?? this.search,
      birthYearFrom: birthYearFrom == _unset
          ? this.birthYearFrom
          : birthYearFrom as int?,
      birthYearTo: birthYearTo == _unset
          ? this.birthYearTo
          : birthYearTo as int?,
      countryId: countryId == _unset
          ? this.countryId
          : countryId as String?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? this.page,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  static const _unset = Object();
}