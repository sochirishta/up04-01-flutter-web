class Author {
  final int id;
  final String firstName;
  final String lastName;
  final String country;
  final DateTime? deletedAt;

  const Author({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.country,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Author copyWith({
    String? firstName,
    String? lastName,
    String? country,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Author(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      country: country ?? this.country,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}

const seedAuthors = <Author>[
  Author(
    id: 1,
    firstName: 'Лев',
    lastName: 'Толстой',
    country: 'Россия',
  ),
  Author(
    id: 2,
    firstName: 'Фёдор',
    lastName: 'Достоевский',
    country: 'Россия',
  ),
  Author(
    id: 3,
    firstName: 'Антон',
    lastName: 'Чехов',
    country: 'Россия',
  ),
  Author(
    id: 4,
    firstName: 'Джордж',
    lastName: 'Оруэлл',
    country: 'Великобритания',
  ),
  Author(
    id: 5,
    firstName: 'Эрнест',
    lastName: 'Хемингуэй',
    country: 'США',
  ),
  Author(
    id: 6,
    firstName: 'Франц',
    lastName: 'Кафка',
    country: 'Чехия',
  ),
  Author(
    id: 7,
    firstName: 'Рэй',
    lastName: 'Брэдбери',
    country: 'США',
  ),
  Author(
    id: 8,
    firstName: 'Габриэль',
    lastName: 'Гарсиа Маркес',
    country: 'Колумбия',
  ),
];