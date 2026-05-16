import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_model.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';
import '../core/app_config.dart';

class AuthProvider extends ChangeNotifier {
  AuthUser? _user;
  bool _loading = false;
  String? _error;

  AuthUser? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  String get token => _user?.token ?? '';

  final ApiService _api = ApiService();
  final FcmService _fcm = FcmService();

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(AppConfig.userKey);
    if (userData == null) return;
    try {
      final map = jsonDecode(userData) as Map<String, dynamic>;
      _user = AuthUser.fromJson(map, map['token'] ?? '');
      notifyListeners();
      _tryRefreshInBackground(prefs);
    } catch (_) {}
  }

  Future<void> _tryRefreshInBackground(SharedPreferences prefs) async {
    final refreshToken = prefs.getString('refresh_token');
    final userId = _user?.id;
    if (refreshToken == null || userId == null || userId.isEmpty) return;

    final newToken = await _api.refreshToken(userId, refreshToken);
    if (newToken != null && _user != null) {
      _user = AuthUser(
        id: _user!.id,
        email: _user!.email,
        name: _user!.name,
        role: _user!.role,
        token: newToken,
        refreshToken: refreshToken,
      );
      final map = _user!.toJson()..['token'] = newToken;
      await prefs.setString(AppConfig.userKey, jsonEncode(map));
      notifyListeners();
      // أعد تسجيل FCM token بالـ token الجديد
      await _fcm.registerTokenOnServer(newToken);
    }
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _api.login(email, password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConfig.userKey, jsonEncode(_user!.toJson()));
      if (_user!.refreshToken != null) {
        await prefs.setString('refresh_token', _user!.refreshToken!);
      }
      _loading = false;
      notifyListeners();
      // سجّل FCM token في الخلفية بعد اللوجن
      _fcm.registerTokenOnServer(_user!.token);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'خطأ في الاتصال. تحقق من الخادم.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    final userId = _user?.id;

    if (refreshToken != null && userId != null && userId.isNotEmpty) {
      await _api.logout(userId, refreshToken);
    }

    _user = null;
    await prefs.remove(AppConfig.userKey);
    await prefs.remove('refresh_token');
    notifyListeners();
  }
}
