import '../entities/user.dart';

abstract interface class AuthRepository {
  Future<AppUser?> login(String email, String password);
  Future<void> logout();
  Future<AppUser?> getCurrentUser();
  Future<void> updateProfile(String uid, AppUser user);
}
