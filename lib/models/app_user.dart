enum Role {
  viewer,
  manager,
  admin;

  int get level {
    switch (this) {
      case Role.viewer:
        return 1;
      case Role.manager:
        return 2;
      case Role.admin:
        return 3;
    }
  }

  bool isAtLeast(Role requiredRole) {
    return level >= requiredRole.level;
  }

  static Role fromJson(dynamic value) {
    switch (value?.toString()) {
      case 'admin':
        return Role.admin;
      case 'manager':
        return Role.manager;
      case 'viewer':
      default:
        return Role.viewer;
    }
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.email,
  });

  final String id;
  final String username;
  final String fullName;
  final Role role;
  final String? email;

  bool hasRole(Role requiredRole) {
    return role.isAtLeast(requiredRole);
  }

  bool isExactly(Role requiredRole) {
    return role == requiredRole;
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final username =
    (json['username'] ?? json['email'] ?? '').toString();

    final fullName =
    (json['name'] ?? json['fullName'] ?? username).toString();

    return AppUser(
      id: (json['id'] ?? '').toString(),
      username: username,
      fullName: fullName,
      role: Role.fromJson(json['role']),
      email: json['email']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': fullName,
      'role': role.name,
      'email': email,
    };
  }

  AppUser copyWith({
    String? id,
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
}