class HallQuery {
  final String search;
  final int? capacityFrom;
  final int? capacityTo;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const HallQuery({
    this.search = '',
    this.capacityFrom,
    this.capacityTo,
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  HallQuery copyWith({
    String? search,
    Object? capacityFrom = _unset,
    Object? capacityTo = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return HallQuery(
      search: search ?? this.search,
      capacityFrom: capacityFrom == _unset
          ? this.capacityFrom
          : capacityFrom as int?,
      capacityTo: capacityTo == _unset
          ? this.capacityTo
          : capacityTo as int?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? this.page,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  static const _unset = Object();
}