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
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
