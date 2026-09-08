class Loan {
  final int id;
  final int readerId;
  final int bookId;
  final DateTime issuedAt;
  final DateTime dueAt;
  final DateTime? returnedAt;
  final String status;

  const Loan({
    required this.id,
    required this.readerId,
    required this.bookId,
    required this.issuedAt,
    required this.dueAt,
    this.returnedAt,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'readerId': readerId,
      'bookId': bookId,
      'issuedAt': issuedAt.toIso8601String(),
      'dueAt': dueAt.toIso8601String(),
      'returnedAt': returnedAt?.toIso8601String(),
      'status': status,
    };
  }

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] as int? ?? 0,
      readerId: json['readerId'] as int? ?? 0,
      bookId: json['bookId'] as int? ?? 0,
      issuedAt: DateTime.tryParse(
        json['issuedAt'] as String? ?? '',
      ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      dueAt: DateTime.tryParse(
        json['dueAt'] as String? ?? '',
      ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      returnedAt: json['returnedAt'] == null
          ? null
          : DateTime.tryParse(json['returnedAt'] as String),
      status: json['status'] as String? ?? 'active',
    );
  }

  Loan copyWith({
    int? readerId,
    int? bookId,
    DateTime? issuedAt,
    DateTime? dueAt,
    DateTime? returnedAt,
    String? status,
    bool clearReturnedAt = false,
  }) {
    return Loan(
      id: id,
      readerId: readerId ?? this.readerId,
      bookId: bookId ?? this.bookId,
      issuedAt: issuedAt ?? this.issuedAt,
      dueAt: dueAt ?? this.dueAt,
      returnedAt: clearReturnedAt
          ? null
          : (returnedAt ?? this.returnedAt),
      status: status ?? this.status,
    );
  }
}

final List<Loan> seedLoans = [
  Loan(
    id: 1,
    readerId: 1,
    bookId: 1,
    issuedAt: DateTime(2026, 8, 20),
    dueAt: DateTime(2026, 9, 3),
    returnedAt: DateTime(2026, 8, 30),
    status: 'returned',
  ),
  Loan(
    id: 2,
    readerId: 2,
    bookId: 2,
    issuedAt: DateTime(2026, 9, 1),
    dueAt: DateTime(2026, 9, 15),
    returnedAt: null,
    status: 'active',
  ),
  Loan(
    id: 3,
    readerId: 3,
    bookId: 3,
    issuedAt: DateTime(2026, 8, 10),
    dueAt: DateTime(2026, 8, 24),
    returnedAt: null,
    status: 'overdue',
  ),
  Loan(
    id: 4,
    readerId: 4,
    bookId: 4,
    issuedAt: DateTime(2026, 8, 28),
    dueAt: DateTime(2026, 9, 11),
    returnedAt: null,
    status: 'active',
  ),
  Loan(
    id: 5,
    readerId: 1,
    bookId: 5,
    issuedAt: DateTime(2026, 7, 15),
    dueAt: DateTime(2026, 7, 29),
    returnedAt: DateTime(2026, 7, 27),
    status: 'returned',
  ),
];