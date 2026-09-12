import '../entities/user.dart';

abstract interface class AuthRepository {
  Future<AppUser?> login(String email, String password);
  Future<void> logout();
  Future<AppUser?> getCurrentUser();
  Future<void> updateProfile(String uid, AppUser user);
  Future<void> updateUser(AppUser user);
  Future<List<AppUser>> getAllUsers();
  Future<void> createUser(AppUser user, {String? password});
  Future<void> deleteUser(String uid);
  Future<void> sendPasswordResetEmail(String email);
}
