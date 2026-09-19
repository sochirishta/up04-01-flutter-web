class Hall {
  final String id;
  final String name;
  final int capacity;
  final DateTime? deletedAt;

  const Hall({
    required this.id,
    required this.name,
    required this.capacity,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'capacity': capacity,
      'deletedAt':
      deletedAt?.toUtc().toIso8601String() ?? '',
    };
  }

  factory Hall.fromJson(Map<String, dynamic> json) {
    return Hall(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      capacity:
      (json['capacity'] as num?)?.toInt() ?? 0,
      deletedAt: _readDateTime(
        json['deletedAt'],
      ),
    );
  }

  Hall copyWith({
    String? name,
    int? capacity,
    Object? deletedAt = _unset,
  }) {
    return Hall(
      id: id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      deletedAt: deletedAt == _unset
          ? this.deletedAt
          : deletedAt as DateTime?,
    );
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value is! String || value.isNotEmpty == false) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  static const _unset = Object();
}