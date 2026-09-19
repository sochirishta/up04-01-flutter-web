class Movie {
  final String id;
  final String title;
  final int year;
  final int duration;
  final List<String> genreIds;
  final List<String> personIds;
  final DateTime? deletedAt;

  const Movie({
    required this.id,
    required this.title,
    required this.year,
    required this.duration,
    required this.genreIds,
    required this.personIds,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'year': year,
      'duration': duration,
      'genres': genreIds,
      'persons': personIds,
      'deletedAt':
      deletedAt?.toUtc().toIso8601String() ?? '',
    };
  }

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      year:
      (json['year'] as num?)?.toInt() ?? 0,
      duration:
      (json['duration'] as num?)?.toInt() ?? 0,
      genreIds: _readStringList(
        json['genres'] ?? json['genreIds'],
      ),
      personIds: _readStringList(
        json['persons'] ?? json['personIds'],
      ),
      deletedAt: _readDateTime(
        json['deletedAt'],
      ),
    );
  }

  Movie copyWith({
    String? title,
    int? year,
    int? duration,
    List<String>? genreIds,
    List<String>? personIds,
    Object? deletedAt = _unset,
  }) {
    return Movie(
      id: id,
      title: title ?? this.title,
      year: year ?? this.year,
      duration: duration ?? this.duration,
      genreIds: genreIds ?? this.genreIds,
      personIds: personIds ?? this.personIds,
      deletedAt: deletedAt == _unset
          ? this.deletedAt
          : deletedAt as DateTime?,
    );
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) {
      return <String>[];
    }

    return value.whereType<String>().toList();
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  static const _unset = Object();
}