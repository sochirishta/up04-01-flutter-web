import 'package:dio/dio.dart';

import '../models/app_user.dart';
import 'api_exceptions.dart';

class AuthResult {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final AppUser user;

  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: json['expiresIn'] as int,
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  Future<AuthResult> login(String username, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'username': username, 'password': password},
    );

    return AuthResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AppUser> register({
    required String username,
    required String password,
    required String email,
    required String fullName,
  }) async {
    final response = await _dio.post(
      '/auth/register',
      data: {
        'username': username,
        'password': password,
        'email': email,
        'fullName': fullName,
      },
    );

    return AppUser.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AppUser> me({String? accessToken}) {
    return guard(() async {
      final response = await _dio.get(
        '/auth/me',
        options: accessToken == null
            ? null
            : Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      return AppUser.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<AuthResult> refresh(String refreshToken) {
    return guard(() async {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      return AuthResult.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<void> logout() {
    return guard(() async {
      await _dio.post('/auth/logout');
    });
  }
}
