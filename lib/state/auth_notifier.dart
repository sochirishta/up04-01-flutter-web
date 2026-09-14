import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_exceptions.dart';
import '../core/auth_api.dart';
import '../models/app_user.dart';

class AuthNotifier extends ChangeNotifier {
  static const _kAccessToken = 'auth_access_token';
  static const _kRefreshToken = 'auth_refresh_token';
  static const _kSessionStartedAt = 'auth_session_started_at';
  static const _kUiRole = 'auth_ui_role';
  static const _kLastActivity = 'auth_last_activity';

  static const inactivityDuration = Duration(minutes: 3);
  static const inactivityWarningDuration = Duration(seconds: 30);
  static const maxSessionDuration = Duration(days: 7);

  final SharedPreferences _prefs;
  final AuthApi _api;

  AuthNotifier(this._prefs, this._api);

  AppUser? _user;
  String? _accessToken;

  Future<String?>? _refreshFuture;

  Timer? _inactivityTimer;
  Timer? _inactivityWarningTimer;
  Timer? _maxSessionTimer;

  bool _isInactivityWarning = false;

  AppUser? get user => _user;

  String? get accessToken => _accessToken;

  bool get isAuthenticated => _user != null;

  bool get isInactivityWarning => _isInactivityWarning;

  bool has(Role role) {
    return _user != null && _user!.role.level >= role.level;
  }

  bool isExactly(Role role) {
    return _user != null && _user!.role == role;
  }

  Future<void> restore() async {
    final access = _prefs.getString(_kAccessToken);
    final refresh = _prefs.getString(_kRefreshToken);

    if (access == null || refresh == null || refresh.isEmpty) {
      return;
    }

    _accessToken = access;

    try {
      final serverUser = await _api.me(
        accessToken: _accessToken,
      );

      _user = _applyUiRole(serverUser);

      if (_sessionExpiredByInactivity()) {
        await _clearSession();
        return;
      }

      await _restoreSession();
    } on UnauthorizedException {
      try {
        final newAccessToken = await _refreshWith(refresh);

        if (newAccessToken == null || newAccessToken.isEmpty) {
          return;
        }

        final serverUser = await _api.me(
          accessToken: newAccessToken,
        );

        _user = _applyUiRole(serverUser);

        if (_sessionExpiredByInactivity()) {
          await _clearSession();
          return;
        }

        await _restoreSession();
      } catch (_) {
        await _clearSession();
      }
    } catch (_) {
      await _clearSession();
    }

    notifyListeners();
  }

  AppUser _applyUiRole(AppUser serverUser) {
    final storedRole = _prefs.getString(_kUiRole);

    if (storedRole == null) {
      _prefs.setString(_kUiRole, serverUser.role.value);
      return serverUser;
    }

    try {
      final uiRole = Role.fromJson(storedRole);

      return serverUser.copyWith(
        role: uiRole,
      );
    } catch (_) {
      _prefs.setString(
        _kUiRole,
        serverUser.role.value,
      );

      return serverUser;
    }
  }

  bool _sessionExpiredByInactivity() {
    final lastActivity = _prefs.getInt(_kLastActivity);

    if (lastActivity == null) {
      return false;
    }

    final elapsed = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(lastActivity),
    );

    return elapsed >= inactivityDuration;
  }

  Future<AppUser> register({
    required String username,
    required String password,
    required String email,
    required String fullName,
  }) {
    return _api.register(
      username: username,
      password: password,
      email: email,
      fullName: fullName,
    );
  }

  Future<void> login(
      String username,
      String password,
      ) async {
    final result = await _api.login(
      username,
      password,
    );

    _accessToken = result.accessToken;
    _user = result.user;

    await _prefs.setString(
      _kAccessToken,
      result.accessToken,
    );

    await _prefs.setString(
      _kRefreshToken,
      result.refreshToken,
    );

    await _prefs.setString(
      _kUiRole,
      result.user.role.value,
    );

    await _prefs.setInt(
      _kSessionStartedAt,
      DateTime.now().millisecondsSinceEpoch,
    );

    await _prefs.setInt(
      _kLastActivity,
      DateTime.now().millisecondsSinceEpoch,
    );

    _startSessionTimers();

    notifyListeners();
  }

  Future<String?> refreshTokens() async {
    final refresh = _prefs.getString(_kRefreshToken);

    if (refresh == null || refresh.isEmpty) {
      await _clearSession();
      return null;
    }

    return _refreshWith(refresh);
  }

  Future<String?> _refreshWith(String refreshToken) async {
    final existing = _refreshFuture;

    if (existing != null) {
      return existing;
    }

    final future = _performRefresh(refreshToken);

    _refreshFuture = future;

    try {
      return await future;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<String?> _performRefresh(String refreshToken) async {
    try {
      final result = await _api.refresh(
        refreshToken,
      );

      _accessToken = result.accessToken;

      final currentUiRole = _prefs.getString(
        _kUiRole,
      );

      _user = result.user;

      if (currentUiRole != null) {
        try {
          _user = _user!.copyWith(
            role: Role.fromJson(currentUiRole),
          );
        } catch (_) {}
      }

      await _prefs.setString(
        _kAccessToken,
        result.accessToken,
      );

      await _prefs.setString(
        _kRefreshToken,
        result.refreshToken,
      );

      notifyListeners();

      return result.accessToken;
    } on UnauthorizedException {
      await _clearSession();
      return null;
    } catch (_) {
      await _clearSession();
      return null;
    }
  }

  void recordActivity() {
    if (!isAuthenticated) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    _prefs.setInt(
      _kLastActivity,
      now,
    );

    _isInactivityWarning = false;

    _inactivityWarningTimer?.cancel();
    _inactivityWarningTimer = null;

    _inactivityTimer?.cancel();

    _inactivityTimer = Timer(
      inactivityDuration - inactivityWarningDuration,
      _showInactivityWarning,
    );

    notifyListeners();
  }

  void _showInactivityWarning() {
    if (!isAuthenticated) {
      return;
    }

    _isInactivityWarning = true;

    notifyListeners();

    _inactivityWarningTimer = Timer(
      inactivityWarningDuration,
          () async {
        if (isAuthenticated) {
          await logout();
        }
      },
    );
  }

  void _startSessionTimers() {
    _cancelSessionTimers();

    _isInactivityWarning = false;

    final lastActivity = _prefs.getInt(
      _kLastActivity,
    );

    Duration inactivityRemaining = inactivityDuration;

    if (lastActivity != null) {
      final elapsed = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(lastActivity),
      );

      inactivityRemaining = inactivityDuration - elapsed;
    }

    if (inactivityRemaining <= Duration.zero) {
      Future<void>(() => _clearSession());
      return;
    }

    if (inactivityRemaining <= inactivityWarningDuration) {
      _showInactivityWarning();
    } else {
      _inactivityTimer = Timer(
        inactivityRemaining - inactivityWarningDuration,
        _showInactivityWarning,
      );
    }

    final startedAt = _prefs.getInt(
      _kSessionStartedAt,
    );

    if (startedAt == null) {
      return;
    }

    final sessionStartedAt = DateTime.fromMillisecondsSinceEpoch(
      startedAt,
    );

    final elapsed = DateTime.now().difference(
      sessionStartedAt,
    );

    final remaining = maxSessionDuration - elapsed;

    if (remaining <= Duration.zero) {
      Future<void>(() => _clearSession());
      return;
    }

    _maxSessionTimer = Timer(
      remaining,
          () async {
        if (isAuthenticated) {
          await logout();
        }
      },
    );
  }

  Future<void> _restoreSession() async {
    final startedAt = _prefs.getInt(
      _kSessionStartedAt,
    );

    if (startedAt == null) {
      await _prefs.setInt(
        _kSessionStartedAt,
        DateTime.now().millisecondsSinceEpoch,
      );
    }

    final lastActivity = _prefs.getInt(
      _kLastActivity,
    );

    if (lastActivity == null) {
      await _prefs.setInt(
        _kLastActivity,
        DateTime.now().millisecondsSinceEpoch,
      );
    }

    _startSessionTimers();
  }

  void _cancelSessionTimers() {
    _inactivityTimer?.cancel();
    _inactivityWarningTimer?.cancel();
    _maxSessionTimer?.cancel();

    _inactivityTimer = null;
    _inactivityWarningTimer = null;
    _maxSessionTimer = null;
  }

  Future<void> logout() async {
    if (_accessToken != null) {
      try {
        await _api.logout();
      } catch (_) {}
    }

    await _clearSession();
  }

  Future<void> _clearSession() async {
    _cancelSessionTimers();

    _isInactivityWarning = false;

    _user = null;
    _accessToken = null;

    await _prefs.remove(
      _kAccessToken,
    );

    await _prefs.remove(
      _kRefreshToken,
    );

    await _prefs.remove(
      _kSessionStartedAt,
    );

    await _prefs.remove(
      _kUiRole,
    );

    await _prefs.remove(
      _kLastActivity,
    );

    notifyListeners();
  }

  @override
  void dispose() {
    _cancelSessionTimers();
    super.dispose();
  }
}