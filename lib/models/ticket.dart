class Ticket {
  final String id;
  final String bookingId;
  final String number;
  final DateTime issuedAt;
  final DateTime? deletedAt;

  const Ticket({
    required this.id,
    required this.bookingId,
    required this.number,
    required this.issuedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking': bookingId,
      'number': number,
      'issuedAt': issuedAt.toIso8601String(),
      'deletedAt':
      deletedAt?.toUtc().toIso8601String() ?? '',
    };
  }

  factory Ticket.fromJson(
      Map<String, dynamic> json,
      ) {
    final booking = json['booking'];

    return Ticket(
      id: json['id'] as String? ?? '',
      bookingId: booking is Map
          ? booking['id'] as String? ?? ''
          : booking as String? ?? '',
      number: json['number'] as String? ?? '',
      issuedAt: DateTime.tryParse(
        json['issuedAt'] as String? ?? '',
      ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      deletedAt: _readDateTime(
        json['deletedAt'],
      ),
    );
  }

  Ticket copyWith({
    String? bookingId,
    String? number,
    DateTime? issuedAt,
    Object? deletedAt = _unset,
  }) {
    return Ticket(
      id: id,
      bookingId: bookingId ?? this.bookingId,
      number: number ?? this.number,
      issuedAt: issuedAt ?? this.issuedAt,
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