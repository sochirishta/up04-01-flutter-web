class LibraryCard {
  final int id;
  final String number;
  final DateTime issuedAt;
  final DateTime expiresAt;

  const LibraryCard({
    required this.id,
    required this.number,
    required this.issuedAt,
    required this.expiresAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'issuedAt': issuedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory LibraryCard.fromJson(Map<String, dynamic> json) {
    return LibraryCard(
      id: json['id'] as int? ?? 0,
      number: json['number'] as String? ?? '',
      issuedAt:
          DateTime.tryParse(json['issuedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      expiresAt:
          DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  LibraryCard copyWith({
    String? number,
    DateTime? issuedAt,
    DateTime? expiresAt,
  }) {
    return LibraryCard(
      id: id,
      number: number ?? this.number,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
