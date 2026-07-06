import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<AppUser?> login(String email, String password) async {
    final trimmedEmail = email.trim();
    UserCredential credential;
    try {
      credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        if (trimmedEmail == 'putri@smktibazma.com' ||
            trimmedEmail == 'guru@sekolah.com' ||
            trimmedEmail == 'siswa@sekolah.com') {
          credential = await _firebaseAuth.createUserWithEmailAndPassword(
            email: trimmedEmail,
            password: password,
          );
          
          final firebaseUser = credential.user;
          if (firebaseUser != null) {
            final isGuru = trimmedEmail == 'putri@smktibazma.com' || trimmedEmail == 'guru@sekolah.com';
            final defaultUser = AppUser(
              uid: firebaseUser.uid,
              email: trimmedEmail,
              displayName: trimmedEmail == 'putri@smktibazma.com'
                  ? 'Putri, S.Pd.'
                  : (isGuru ? 'Fadhil Rabbani, M.Pd.' : 'Fadhil Rabbani'),
              role: isGuru ? 'guru' : 'siswa',
              nickname: trimmedEmail == 'putri@smktibazma.com'
                  ? 'Putri'
                  : 'Fadhil',
              birthDate: trimmedEmail == 'putri@smktibazma.com' ? '15 Agustus 1990' : null,
              address: trimmedEmail == 'putri@smktibazma.com' ? 'Jl. Raya Megamendung No. 10, Bogor' : null,
              phoneNumber: trimmedEmail == 'putri@smktibazma.com' ? '089512345678' : null,
              extraField: trimmedEmail == 'putri@smktibazma.com' ? 'Guru Bahasa Inggris' : null,
            );
            await updateProfile(firebaseUser.uid, defaultUser);
            return defaultUser;
          }
        }
      }
      rethrow;
    }

    final firebaseUser = credential.user;
    if (firebaseUser == null) return null;

    return await _getUserFromFirestore(firebaseUser);
  }

  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    return await _getUserFromFirestore(firebaseUser);
  }

  Future<AppUser> _getUserFromFirestore(User firebaseUser) async {
    try {
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return AppUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: data['displayName'] as String? ?? firebaseUser.displayName ?? 'Pengguna',
          role: data['role'] as String? ?? 'siswa',
          avatarUrl: data['avatarUrl'] as String?,
          nickname: data['nickname'] as String?,
          birthDate: data['birthDate'] as String?,
          address: data['address'] as String?,
          phoneNumber: data['phoneNumber'] as String?,
          extraField: data['extraField'] as String?,
        );
      }
    } catch (_) {
      // Safe fallback if Firestore fails or collection doesn't exist
    }

    // Default fallback mapping from Firebase Auth User
    return AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? 'Pengguna',
      role: 'siswa',
      nickname: firebaseUser.displayName?.split(' ').first,
    );
  }

  @override
  Future<void> updateProfile(String uid, AppUser user) async {
    await _firestore.collection('users').doc(uid).set({
      'displayName': user.displayName,
      'nickname': user.nickname,
      'birthDate': user.birthDate,
      'address': user.address,
      'phoneNumber': user.phoneNumber,
      'extraField': user.extraField,
    }, SetOptions(merge: true));
  }
}
