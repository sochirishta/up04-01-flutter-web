class Book {
  final int id;
  final String title;
  final String isbn;
  final int year;
  final int pages;
  final int publisherId;
  final List<int> authorIds;
  final List<int> genreIds;
  final int copiesTotal;
  final int copiesAvailable;
  final DateTime? deletedAt;

  const Book({
    required this.id,
    required this.title,
    required this.isbn,
    required this.year,
    required this.pages,
    required this.publisherId,
    required this.authorIds,
    required this.genreIds,
    required this.copiesTotal,
    required this.copiesAvailable,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isbn': isbn,
      'year': year,
      'pages': pages,
      'publisherId': publisherId,
      'authorIds': authorIds,
      'genreIds': genreIds,
      'copiesTotal': copiesTotal,
      'copiesAvailable': copiesAvailable,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    final publisherId =
        json['publisherId'] as int? ??
        (json['publisher'] is Map
            ? (json['publisher'] as Map)['id'] as int?
            : null) ??
        0;

    final authorIds = json['authorIds'] is List
        ? (json['authorIds'] as List).cast<int>()
        : json['authors'] is List
        ? (json['authors'] as List)
              .whereType<Map>()
              .map((author) => author['id'])
              .whereType<int>()
              .toList()
        : <int>[];

    final genreIds = json['genreIds'] is List
        ? (json['genreIds'] as List).cast<int>()
        : json['genres'] is List
        ? (json['genres'] as List)
              .whereType<Map>()
              .map((genre) => genre['id'])
              .whereType<int>()
              .toList()
        : <int>[];

    return Book(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      isbn: json['isbn'] as String? ?? '',
      year: json['year'] as int? ?? 0,
      pages: json['pages'] as int? ?? 0,
      publisherId: publisherId,
      authorIds: authorIds,
      genreIds: genreIds,
      copiesTotal: json['copiesTotal'] as int? ?? 0,
      copiesAvailable: json['copiesAvailable'] as int? ?? 0,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.tryParse(json['deletedAt'] as String),
    );
  }

  Book copyWith({
    String? title,
    String? isbn,
    int? year,
    int? pages,
    int? publisherId,
    List<int>? authorIds,
    List<int>? genreIds,
    int? copiesTotal,
    int? copiesAvailable,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Book(
      id: id,
      title: title ?? this.title,
      isbn: isbn ?? this.isbn,
      year: year ?? this.year,
      pages: pages ?? this.pages,
      publisherId: publisherId ?? this.publisherId,
      authorIds: authorIds ?? this.authorIds,
      genreIds: genreIds ?? this.genreIds,
      copiesTotal: copiesTotal ?? this.copiesTotal,
      copiesAvailable: copiesAvailable ?? this.copiesAvailable,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
