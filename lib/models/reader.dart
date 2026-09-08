import 'library_card.dart';

class Reader {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final LibraryCard? card;
  final DateTime? deletedAt;

  const Reader({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.card,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'card': card?.toJson(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory Reader.fromJson(Map<String, dynamic> json) {
    final cardJson = json['card'];
    return Reader(
      id: json['id'] as int? ?? 0,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      card: cardJson is Map<String, dynamic>
          ? LibraryCard.fromJson(cardJson)
          : null,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.tryParse(json['deletedAt'] as String),
    );
  }

  Reader copyWith({
    String? fullName,
    String? email,
    String? phone,
    LibraryCard? card,
    DateTime? deletedAt,
    bool clearCard = false,
    bool clearDeletedAt = false,
  }) {
    return Reader(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      card: clearCard ? null : (card ?? this.card),
      deletedAt: clearDeletedAt
          ? null
          : (deletedAt ?? this.deletedAt),
    );
  }
}

final List<Reader> seedReaders = [
  Reader(
    id: 1,
    fullName: 'Иванов Иван Иванович',
    email: 'ivanov@example.com',
    phone: '+79990000001',
    card: LibraryCard(
      id: 1,
      number: 'LIB-000001',
      issuedAt: DateTime(2026, 1, 10),
      expiresAt: DateTime(2027, 1, 10),
    ),
  ),
  Reader(
    id: 2,
    fullName: 'Петров Пётр Петрович',
    email: 'petrov@example.com',
    phone: '+79990000002',
    card: LibraryCard(
      id: 2,
      number: 'LIB-000002',
      issuedAt: DateTime(2026, 2, 15),
      expiresAt: DateTime(2027, 2, 15),
    ),
  ),
  Reader(
    id: 3,
    fullName: 'Сидорова Анна Сергеевна',
    email: 'sidorova@example.com',
    phone: '+79990000003',
    card: LibraryCard(
      id: 3,
      number: 'LIB-000003',
      issuedAt: DateTime(2026, 3, 1),
      expiresAt: DateTime(2027, 3, 1),
    ),
  ),
  Reader(
    id: 4,
    fullName: 'Кузнецов Алексей Викторович',
    email: 'kuznetsov@example.com',
    phone: '+79990000004',
    card: LibraryCard(
      id: 4,
      number: 'LIB-000004',
      issuedAt: DateTime(2026, 3, 20),
      expiresAt: DateTime(2027, 3, 20),
    ),
  ),
];