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
    final reader = json['reader'];
    final book = json['book'];

    return Loan(
      id: json['id'] as int? ?? 0,
      readerId: reader is Map
          ? reader['id'] as int? ?? 0
          : json['readerId'] as int? ?? 0,
      bookId: book is Map
          ? book['id'] as int? ?? 0
          : json['bookId'] as int? ?? 0,
      issuedAt:
          DateTime.tryParse(json['issuedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      dueAt:
          DateTime.tryParse(json['dueAt'] as String? ?? '') ??
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
      returnedAt: clearReturnedAt ? null : (returnedAt ?? this.returnedAt),
      status: status ?? this.status,
    );
  }
}
