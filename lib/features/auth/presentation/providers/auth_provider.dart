import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firebase_auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  const Authenticated(this.user);
  final AppUser user;
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Run initialization asynchronously
    Future.microtask(() => _init());
    return const AuthInitial();
  }

  Future<void> _init() async {
    final repository = ref.read(authRepositoryProvider);
    try {
      final user = await repository.getCurrentUser();
      if (user != null) {
        state = Authenticated(user);
      } else {
        state = const Unauthenticated();
      }
    } catch (_) {
      state = const Unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    final repository = ref.read(authRepositoryProvider);
    try {
      final user = await repository.login(email, password);
      if (user != null) {
        state = Authenticated(user);
      } else {
        state = const AuthError('Gagal masuk. Silakan coba lagi.');
      }
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      state = AuthError(message);
    }
  }

  Future<void> logout() async {
    state = const AuthLoading();
    final repository = ref.read(authRepositoryProvider);
    try {
      await repository.logout();
      state = const Unauthenticated();
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<bool> updateProfile(AppUser updatedUser) async {
    final currentState = state;
    if (currentState is! Authenticated) return false;
    
    final repository = ref.read(authRepositoryProvider);
    try {
      await repository.updateProfile(updatedUser.uid, updatedUser);
      state = Authenticated(updatedUser);
      return true;
    } catch (e) {
      return false;
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
