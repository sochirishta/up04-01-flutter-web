import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth_api.dart';
import '../core/api_exceptions.dart';
import '../models/app_user.dart';

class AuthNotifier extends ChangeNotifier {
  AuthNotifier(this._api);

  final AuthApi _api;

  static const String _kAccessToken = 'auth_access_token';
  static const String _kSessionStartedAt = 'auth_session_started_at';

  static const Duration _inactivityLimit = Duration(minutes: 3);
  static const Duration _inactivityWarning = Duration(seconds: 30);
  static const Duration _maxSessionDuration = Duration(days: 7);

  SharedPreferences? _prefs;

  String? _accessToken;
  AppUser? _user;

  bool _initialized = false;
  bool _loading = false;
  bool _refreshing = false;

  DateTime? _sessionStartedAt;
  DateTime? _lastActivityAt;

  Timer? _activityTimer;
  Future<bool>? _refreshFuture;

  bool _warningShown = false;

  AppUser? get user => _user;

  String? get accessToken => _accessToken;

  bool get isAuthenticated {
    return _accessToken != null && _user != null;
  }

  bool get isLoading => _loading;

  bool get isInitialized => _initialized;

  bool get isRefreshing => _refreshing;

  Duration? get inactivityRemaining {
    if (_lastActivityAt == null) {
      return null;
    }

    final elapsed = DateTime.now().difference(_lastActivityAt!);
    final remaining = _inactivityLimit - elapsed;

    if (remaining.isNegative) {
      return Duration.zero;
    }

    return remaining;
  }

  Duration? get sessionRemaining {
    if (_sessionStartedAt == null) {
      return null;
    }

    final elapsed = DateTime.now().difference(_sessionStartedAt!);
    final remaining = _maxSessionDuration - elapsed;

    if (remaining.isNegative) {
      return Duration.zero;
    }

    return remaining;
  }

  bool hasRole(Role role) {
    return _user?.hasRole(role) ?? false;
  }

  bool isExactly(Role role) {
    return _user?.isExactly(role) ?? false;
  }

  Future<void> restore() async {
    if (_initialized) {
      return;
    }

    _prefs ??= await SharedPreferences.getInstance();

    final token = _prefs!.getString(_kAccessToken);
    final sessionStartedRaw = _prefs!.getInt(_kSessionStartedAt);

    if (token == null || token.isEmpty) {
      _initialized = true;
      notifyListeners();
      return;
    }

    _accessToken = token;

    if (sessionStartedRaw != null) {
      _sessionStartedAt =
          DateTime.fromMillisecondsSinceEpoch(sessionStartedRaw);
    } else {
      _sessionStartedAt = DateTime.now();

      await _prefs!.setInt(
        _kSessionStartedAt,
        _sessionStartedAt!.millisecondsSinceEpoch,
      );
    }

    _lastActivityAt = DateTime.now();

    _loading = true;
    notifyListeners();

    try {
      final result = await _api.refresh(token);

      _accessToken = result.accessToken;
      _user = result.user;

      await _saveAccessToken(result.accessToken);

      if (_sessionExpired()) {
        await _clearSession();
      } else {
        _startActivityTimer();
      }
    } on UnauthorizedException {
      await _clearSession();
    } catch (_) {
    } finally {
      _loading = false;
      _initialized = true;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String identity,
    required String password,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      final result = await _api.login(
        identity,
        password,
      );

      _accessToken = result.accessToken;
      _user = result.user;

      _sessionStartedAt = DateTime.now();
      _lastActivityAt = DateTime.now();
      _warningShown = false;

      await _saveAccessToken(result.accessToken);

      await _prefs!.setInt(
        _kSessionStartedAt,
        _sessionStartedAt!.millisecondsSinceEpoch,
      );

      _startActivityTimer();

      return true;
    } catch (_) {
      await _clearSession();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      await _api.register(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
      );

      return true;
    } catch (_) {
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> refreshTokens() async {
    final token = _accessToken;

    if (token == null || token.isEmpty) {
      return false;
    }

    if (_refreshFuture != null) {
      return _refreshFuture!;
    }

    _refreshFuture = _performRefresh(token);

    try {
      return await _refreshFuture!;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<bool> _performRefresh(String token) async {
    if (_refreshing) {
      return isAuthenticated;
    }

    _refreshing = true;
    notifyListeners();

    try {
      final result = await _api.refresh(token);

      _accessToken = result.accessToken;
      _user = result.user;

      await _saveAccessToken(result.accessToken);

      return true;
    } on UnauthorizedException {
      await _clearSession();
      return false;
    } catch (_) {
      return false;
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  void recordActivity() {
    if (!isAuthenticated) {
      return;
    }

    _lastActivityAt = DateTime.now();
    _warningShown = false;

    if (_activityTimer == null) {
      _startActivityTimer();
    }
  }

  bool consumeInactivityWarning() {
    if (_warningShown) {
      return false;
    }

    final remaining = inactivityRemaining;

    if (remaining == null) {
      return false;
    }

    if (remaining <= _inactivityWarning &&
        remaining > Duration.zero) {
      _warningShown = true;
      return true;
    }

    return false;
  }

  Future<void> logout() async {
    await _clearSession();
    notifyListeners();
  }

  Future<void> _saveAccessToken(String token) async {
    _prefs ??= await SharedPreferences.getInstance();

    await _prefs!.setString(
      _kAccessToken,
      token,
    );
  }

  Future<void> _clearSession() async {
    _accessToken = null;
    _user = null;

    _sessionStartedAt = null;
    _lastActivityAt = null;

    _warningShown = false;

    _activityTimer?.cancel();
    _activityTimer = null;

    _prefs ??= await SharedPreferences.getInstance();

    await _prefs!.remove(_kAccessToken);
    await _prefs!.remove(_kSessionStartedAt);
  }

  bool _sessionExpired() {
    if (_sessionStartedAt == null) {
      return false;
    }

    return DateTime.now().difference(_sessionStartedAt!) >=
        _maxSessionDuration;
  }

  void _startActivityTimer() {
    _activityTimer?.cancel();

    _activityTimer = Timer.periodic(
      const Duration(seconds: 10),
          (_) {
        _checkSession();
      },
    );
  }

  Future<void> _checkSession() async {
    if (!isAuthenticated) {
      return;
    }

    if (_sessionExpired()) {
      await logout();
      return;
    }

    final inactivity = inactivityRemaining;

    if (inactivity != null &&
        inactivity <= Duration.zero) {
      await logout();
      return;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _activityTimer?.cancel();
    super.dispose();
  }
}