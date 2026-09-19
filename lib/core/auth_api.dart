import 'package:dio/dio.dart';

import '../models/app_user.dart';
import 'api_exceptions.dart';

class AuthResult {
  final String accessToken;
  final AppUser user;

  const AuthResult({
    required this.accessToken,
    required this.user,
  });

  factory AuthResult.fromJson(
      Map<String, dynamic> json,
      ) {
    return AuthResult(
      accessToken: json['token'] as String,
      user: AppUser.fromJson(
        json['record'] as Map<String, dynamic>,
      ),
    );
  }
}

class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  Future<AuthResult> login(
      String username,
      String password,
      ) {
    return guard(() async {
      final response = await _dio.post(
        '/collections/users/auth-with-password',
        data: {
          'identity': username,
          'password': password,
        },
      );

      return AuthResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  Future<AppUser> register({
    required String username,
    required String password,
    required String email,
    required String fullName,
  }) {
    return guard(() async {
      final response = await _dio.post(
        '/collections/users/records',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'passwordConfirm': password,
          'name': fullName,
        },
      );

      return AppUser.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  Future<AppUser> me(
      String accessToken,
      ) {
    return guard(() async {
      final response = await _dio.get(
        '/collections/users/auth-refresh',
        options: Options(
          headers: {
            'Authorization': accessToken,
          },
        ),
      );

      return AppUser.fromJson(
        (response.data as Map<String, dynamic>)['record']
        as Map<String, dynamic>,
      );
    });
  }

  Future<AuthResult> refresh(
      String accessToken,
      ) {
    return guard(() async {
      final response = await _dio.post(
        '/collections/users/auth-refresh',
        options: Options(
          headers: {
            'Authorization': accessToken,
          },
        ),
      );

      return AuthResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  Future<void> logout() async {
  }
}