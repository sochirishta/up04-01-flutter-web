class Person {
  final String id;
  final String fullName;
  final int birthYear;
  final String countryId;
  final DateTime? deletedAt;

  const Person({
    required this.id,
    required this.fullName,
    required this.birthYear,
    required this.countryId,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'birthYear': birthYear,
      'country': countryId,
      'deletedAt':
      deletedAt?.toUtc().toIso8601String() ?? '',
    };
  }

  factory Person.fromJson(Map<String, dynamic> json) {
    final country = json['country'];

    return Person(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      birthYear:
      (json['birthYear'] as num?)?.toInt() ?? 0,
      countryId: country is Map
          ? country['id'] as String? ?? ''
          : country as String? ?? '',
      deletedAt: _readDateTime(
        json['deletedAt'],
      ),
    );
  }

  Person copyWith({
    String? fullName,
    int? birthYear,
    String? countryId,
    Object? deletedAt = _unset,
  }) {
    return Person(
      id: id,
      fullName: fullName ?? this.fullName,
      birthYear: birthYear ?? this.birthYear,
      countryId: countryId ?? this.countryId,
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