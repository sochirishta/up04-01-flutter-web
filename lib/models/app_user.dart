enum Role {
  reader,
  librarian,
  admin;

  int get level {
    switch (this) {
      case Role.reader:
        return 1;
      case Role.librarian:
        return 2;
      case Role.admin:
        return 3;
    }
  }

  String get value => name;

  static Role fromJson(String value) {
    switch (value) {
      case 'reader':
        return Role.reader;
      case 'librarian':
        return Role.librarian;
      case 'admin':
        return Role.admin;
      default:
        throw FormatException('Unknown role: $value');
    }
  }
}

class AppUser {
  final int id;
  final String username;
  final String fullName;
  final Role role;
  final String? email;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.email,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      username: json['username'] as String,
      fullName: json['fullName'] as String? ?? '',
      role: Role.fromJson(json['role'] as String),
      email: json['email'] as String?,
    );
  }

  AppUser copyWith({
    int? id,
    String? username,
    String? fullName,
    Role? role,
    String? email,
  }) {
    return AppUser(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'role': role.value,
      if (email != null) 'email': email,
    };
  }

  bool hasRole(Role requiredRole) {
    return role.level >= requiredRole.level;
  }

  bool isExactly(Role requiredRole) {
    return role == requiredRole;
  }
}
