import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _userKey = 'cached_user';

  @override
  Future<AppUser?> login(String email, String password) async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    final trimmedEmail = email.trim().toLowerCase();

    if (password != 'password') {
      throw Exception('Kata sandi salah. Silakan coba lagi (coba: password).');
    }

    AppUser user;
    if (trimmedEmail == 'guru@sekolah.com') {
      user = const AppUser(
        uid: 'guru-123',
        email: 'guru@sekolah.com',
        displayName: 'Pak Fadhil, M.Pd.',
        role: 'guru',
      );
    } else if (trimmedEmail == 'siswa@sekolah.com') {
      user = const AppUser(
        uid: 'siswa-456',
        email: 'siswa@sekolah.com',
        displayName: 'Fadhil',
        role: 'siswa',
      );
    } else {
      throw Exception('Email tidak terdaftar (coba: guru@sekolah.com atau siswa@sekolah.com).');
    }

    await _cacheUser(user);
    return user;
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await _prefs.remove(_userKey);
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final userJson = _prefs.getString(_userKey);
    if (userJson == null) return null;

    try {
      final map = jsonDecode(userJson) as Map<String, dynamic>;
      return AppUser(
        uid: map['uid'] as String,
        email: map['email'] as String,
        displayName: map['displayName'] as String,
        role: map['role'] as String,
        avatarUrl: map['avatarUrl'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheUser(AppUser user) async {
    final map = {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'role': user.role,
      'avatarUrl': user.avatarUrl,
    };
    await _prefs.setString(_userKey, jsonEncode(map));
  }
}
