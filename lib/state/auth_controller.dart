import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/user_model.dart';
import '../data/models/user_role.dart';
import '../data/services/firestore_database.dart';

class AuthActionResult {
  const AuthActionResult({required this.success, required this.message});

  final bool success;
  final String message;
}

class AuthController extends ChangeNotifier {
  AuthController({
    required FirestoreDatabase database,
    required SharedPreferences preferences,
  }) : _database = database,
       _preferences = preferences;

  static const _rememberMeKey = 'remember_me';
  static const _rememberedEmailKey = 'remembered_email';

  final FirestoreDatabase _database;
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
      _currentUser = await _database.currentAppUser();
    } else {
      await _database.logout();
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
    try {
      await _database.register(
        fullName: fullName,
        email: normalizedEmail,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        return const AuthActionResult(
          success: false,
          message: 'Email này đã được đăng ký.',
        );
      }
      return const AuthActionResult(
        success: false,
        message: 'Không thể đăng ký tài khoản. Vui lòng thử lại.',
      );
    }

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
    try {
      final user = await _database.login(email: email, password: password);
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
    } on FirebaseAuthException {
      return const AuthActionResult(
        success: false,
        message: 'Email hoặc mật khẩu không chính xác.',
      );
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _rememberMe = false;
    await _database.logout();
    await _preferences.setBool(_rememberMeKey, false);
    await _preferences.remove(_rememberedEmailKey);
    notifyListeners();
  }
}
