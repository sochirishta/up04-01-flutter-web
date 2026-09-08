class Author {
  final int id;
  final String fullName;
  final int birthYear;
  final String country;
  final DateTime? deletedAt;

  const Author({
    required this.id,
    required this.fullName,
    required this.birthYear,
    required this.country,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'birthYear': birthYear,
      'country': country,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'] as int? ?? 0,
      fullName: json['fullName'] as String? ?? '',
      birthYear: json['birthYear'] as int? ?? 0,
      country: json['country'] as String? ?? '',
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.tryParse(json['deletedAt'] as String),
    );
  }

  Author copyWith({
    String? fullName,
    int? birthYear,
    String? country,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Author(
      id: id,
      fullName: fullName ?? this.fullName,
      birthYear: birthYear ?? this.birthYear,
      country: country ?? this.country,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}

const seedAuthors = <Author>[
  Author(
    id: 1,
    fullName: 'Лев Толстой',
    birthYear: 1828,
    country: 'Россия',
  ),
  Author(
    id: 2,
    fullName: 'Фёдор Достоевский',
    birthYear: 1821,
    country: 'Россия',
  ),
  Author(
    id: 3,
    fullName: 'Антон Чехов',
    birthYear: 1860,
    country: 'Россия',
  ),
  Author(
    id: 4,
    fullName: 'Джордж Оруэлл',
    birthYear: 1903,
    country: 'Великобритания',
  ),
  Author(
    id: 5,
    fullName: 'Эрнест Хэмингуей',
    birthYear: 1899,
    country: 'США',
  ),
  Author(
    id: 6,
    fullName: 'Франц Кафка',
    birthYear: 1920,
    country: 'Чехия',
  ),
  Author(
    id: 7,
    fullName: 'Рэй Брэдбери',
    birthYear: 1920,
    country: 'США',
  ),
  Author(
    id: 8,
    fullName: 'Габриэль Гарсиа Маркес',
    birthYear: 1927,
    country: 'Колумбия',
  ),
];