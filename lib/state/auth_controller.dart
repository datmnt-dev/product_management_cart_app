import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/password_hash.dart';
import '../data/models/user_model.dart';
import '../data/models/user_role.dart';
import '../data/services/local_database.dart';

class AuthActionResult {
  const AuthActionResult({required this.success, required this.message});

  final bool success;
  final String message;
}

class AuthController extends ChangeNotifier {
  AuthController({
    required LocalDatabase database,
    required SharedPreferences preferences,
  }) : _database = database,
       _preferences = preferences;

  static const _rememberMeKey = 'remember_me';
  static const _rememberedEmailKey = 'remembered_email';

  final LocalDatabase _database;
  final SharedPreferences _preferences;

  AppUser? _currentUser;
  bool _rememberMe = false;
  bool _isReady = false;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get rememberMe => _rememberMe;
  bool get isReady => _isReady;

  Future<void> bootstrap() async {
    _rememberMe = _preferences.getBool(_rememberMeKey) ?? false;
    if (_rememberMe) {
      final email = _preferences.getString(_rememberedEmailKey);
      if (email != null) {
        _currentUser = _database.getUserByEmail(email);
      }
    }
    _isReady = true;
    notifyListeners();
  }

  Future<AuthActionResult> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (_database.emailExists(normalizedEmail)) {
      return const AuthActionResult(
        success: false,
        message: 'Email này đã được đăng ký.',
      );
    }

    final user = AppUser(
      id: _createId('user'),
      fullName: fullName.trim(),
      email: normalizedEmail,
      passwordHash: hashPassword(password),
      role: AppRole.customer,
      createdAt: DateTime.now(),
    );

    await _database.saveUser(user);
    return const AuthActionResult(
      success: true,
      message: 'Đăng ký thành công. Vui lòng đăng nhập.',
    );
  }

  Future<AuthActionResult> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final user = _database.getUserByEmail(email);
    if (user == null || user.passwordHash != hashPassword(password)) {
      return const AuthActionResult(
        success: false,
        message: 'Email hoặc mật khẩu không chính xác.',
      );
    }

    _currentUser = user;
    _rememberMe = rememberMe;

    await _preferences.setBool(_rememberMeKey, rememberMe);
    if (rememberMe) {
      await _preferences.setString(_rememberedEmailKey, user.email);
    } else {
      await _preferences.remove(_rememberedEmailKey);
    }

    notifyListeners();
    return AuthActionResult(
      success: true,
      message: 'Xin chào ${user.fullName} (${user.role.label}).',
    );
  }

  Future<void> logout() async {
    _currentUser = null;
    _rememberMe = false;
    await _preferences.setBool(_rememberMeKey, false);
    await _preferences.remove(_rememberedEmailKey);
    notifyListeners();
  }

  static String _createId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }
}
