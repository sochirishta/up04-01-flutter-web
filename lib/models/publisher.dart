class Publisher {
  final int id;
  final String name;
  final String city;
  final int foundedYear;
  final DateTime? deletedAt;

  const Publisher({
    required this.id,
    required this.name,
    required this.city,
    required this.foundedYear,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'city': city,
    'foundedYear': foundedYear,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Publisher.fromJson(Map<String, dynamic> json) => Publisher(
    id: json['id'] as int? ?? 0,
    name: json['name'] as String? ?? '',
    city: json['city'] as String? ?? '',
    foundedYear: json['foundedYear'] as int? ?? 0,
    deletedAt: json['deletedAt'] == null
        ? null
        : DateTime.tryParse(json['deletedAt'] as String),
  );

  Publisher copyWith({
    String? name,
    String? city,
    int? foundedYear,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) =>
      Publisher(
        id: id,
        name: name ?? this.name,
        city: city ?? this.city,
        foundedYear: foundedYear ?? this.foundedYear,
        deletedAt:
        clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      );
}

const List<Publisher> seedPublishers = [
  Publisher(
    id: 1,
    name: 'Эксмо',
    city: 'Москва',
    foundedYear: 1993,
  ),
  Publisher(
    id: 2,
    name: 'АСТ',
    city: 'Москва',
    foundedYear: 1990,
  ),
  Publisher(
    id: 3,
    name: 'МИФ',
    city: 'Москва',
    foundedYear: 2005,
  ),
  Publisher(
    id: 4,
    name: 'Азбука',
    city: 'Санкт-Петербург',
    foundedYear: 1995,
  ),
  Publisher(
    id: 5,
    name: 'Penguin Books',
    city: 'London',
    foundedYear: 1935,
  ),
  Publisher(
    id: 6,
    name: 'HarperCollins',
    city: 'New York',
    foundedYear: 1989,
  ),
  Publisher(
    id: 7,
    name: 'Росмэн',
    city: 'Москва',
    foundedYear: 1992,
  ),
  Publisher(
    id: 8,
    name: 'Иностранка',
    city: 'Москва',
    foundedYear: 2000,
  ),
];