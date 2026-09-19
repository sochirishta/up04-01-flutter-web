class Country {
  final String id;
  final String name;
  final DateTime? deletedAt;

  const Country({
    required this.id,
    required this.name,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'deletedAt':
      deletedAt?.toUtc().toIso8601String() ?? '',
    };
  }

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      deletedAt: _readDateTime(
        json['deletedAt'],
      ),
    );
  }

  Country copyWith({
    String? name,
    Object? deletedAt = _unset,
  }) {
    return Country(
      id: id,
      name: name ?? this.name,
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