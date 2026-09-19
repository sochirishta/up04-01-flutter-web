class CinemaSession {
  final String id;
  final String movieId;
  final String hallId;
  final DateTime date;
  final DateTime? deletedAt;

  const CinemaSession({
    required this.id,
    required this.movieId,
    required this.hallId,
    required this.date,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'movie': movieId,
      'hall': hallId,
      'date': date.toIso8601String(),
      'deletedAt':
      deletedAt?.toUtc().toIso8601String() ?? '',
    };
  }

  factory CinemaSession.fromJson(
      Map<String, dynamic> json,
      ) {
    final movie = json['movie'];
    final hall = json['hall'];

    return CinemaSession(
      id: json['id'] as String? ?? '',
      movieId: movie is Map
          ? movie['id'] as String? ?? ''
          : movie as String? ?? '',
      hallId: hall is Map
          ? hall['id'] as String? ?? ''
          : hall as String? ?? '',
      date: DateTime.tryParse(
        json['date'] as String? ?? '',
      ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      deletedAt: _readDateTime(
        json['deletedAt'],
      ),
    );
  }

  CinemaSession copyWith({
    String? movieId,
    String? hallId,
    DateTime? date,
    Object? deletedAt = _unset,
  }) {
    return CinemaSession(
      id: id,
      movieId: movieId ?? this.movieId,
      hallId: hallId ?? this.hallId,
      date: date ?? this.date,
      deletedAt: deletedAt == _unset
          ? this.deletedAt
          : deletedAt as DateTime?,
    );
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  static const _unset = Object();
}