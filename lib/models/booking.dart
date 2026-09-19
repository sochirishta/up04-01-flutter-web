class Booking {
  final String id;
  final String sessionId;
  final String userId;
  final int row;
  final int seat;
  final DateTime? deletedAt;

  const Booking({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.row,
    required this.seat,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session': sessionId,
      'user': userId,
      'row': row,
      'seat': seat,
      'deletedAt':
      deletedAt?.toUtc().toIso8601String() ?? '',
    };
  }

  factory Booking.fromJson(
      Map<String, dynamic> json,
      ) {
    final session = json['session'];
    final user = json['user'];

    return Booking(
      id: json['id'] as String? ?? '',
      sessionId: session is Map
          ? session['id'] as String? ?? ''
          : session as String? ?? '',
      userId: user is Map
          ? user['id'] as String? ?? ''
          : user as String? ?? '',
      row: (json['row'] as num?)?.toInt() ?? 0,
      seat:
      (json['seat'] as num?)?.toInt() ?? 0,
      deletedAt: _readDateTime(
        json['deletedAt'],
      ),
    );
  }

  Booking copyWith({
    String? sessionId,
    String? userId,
    int? row,
    int? seat,
    Object? deletedAt = _unset,
  }) {
    return Booking(
      id: id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      row: row ?? this.row,
      seat: seat ?? this.seat,
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