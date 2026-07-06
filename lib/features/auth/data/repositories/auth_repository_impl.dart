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
        if (trimmedEmail == 'amel@smktibazma.com' ||
            trimmedEmail == 'guru@sekolah.com' ||
            trimmedEmail == 'siswa@sekolah.com') {
          credential = await _firebaseAuth.createUserWithEmailAndPassword(
            email: trimmedEmail,
            password: password,
          );
          
          final firebaseUser = credential.user;
          if (firebaseUser != null) {
            final isGuru = trimmedEmail == 'amel@smktibazma.com' || trimmedEmail == 'guru@sekolah.com';
            final defaultUser = AppUser(
              uid: firebaseUser.uid,
              email: trimmedEmail,
              displayName: trimmedEmail == 'amel@smktibazma.com'
                  ? 'Amel, S.Pd.'
                  : (isGuru ? 'Fadhil Rabbani, M.Pd.' : 'Fadhil Rabbani'),
              role: isGuru ? 'guru' : 'siswa',
              nickname: trimmedEmail == 'amel@smktibazma.com'
                  ? 'Amel'
                  : 'Fadhil',
              birthDate: trimmedEmail == 'amel@smktibazma.com' ? '15 Agustus 1990' : null,
              address: trimmedEmail == 'amel@smktibazma.com' ? 'Jl. Raya Megamendung No. 10, Bogor' : null,
              phoneNumber: trimmedEmail == 'amel@smktibazma.com' ? '089512345678' : null,
              extraField: trimmedEmail == 'amel@smktibazma.com' ? 'Guru Matematika' : null,
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

  Future<void> _seedDummyCollections() async {
    try {
      final classesCol = _firestore.collection('classes');

      final classIds = ['X', 'XI', 'XII'];
      for (final classId in classIds) {
        final classDoc = classesCol.doc(classId);
        await classDoc.set({
          'name': 'Kelas $classId',
        });
        // Subcollection 'rooms' inside classes/{classId}
        await classDoc.collection('rooms').doc('Room_A').set({'name': 'Room A'});
        await classDoc.collection('rooms').doc('Room_B').set({'name': 'Room B'});
      }
    } catch (_) {}
  }

  Future<AppUser> _getUserFromFirestore(User firebaseUser) async {
    // Seed classes & rooms in background
    _seedDummyCollections();

    final email = firebaseUser.email ?? '';
    final isGuruEmail = email == 'amel@smktibazma.com' || email == 'guru@sekolah.com';
    final defaultRole = isGuruEmail ? 'guru' : 'siswa';

    try {
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final role = data['role'] as String? ?? defaultRole;

        // If it's a teacher but the database role is missing or set to student, auto-update it
        if (isGuruEmail && role != 'guru') {
          await _firestore.collection('users').doc(firebaseUser.uid).set({
            'role': 'guru',
          }, SetOptions(merge: true));
        }

        return AppUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: data['displayName'] as String? ?? firebaseUser.displayName ?? (isGuruEmail ? 'Amel, S.Pd.' : 'Pengguna'),
          role: isGuruEmail ? 'guru' : role,
          avatarUrl: data['avatarUrl'] as String?,
          nickname: data['nickname'] as String? ?? (isGuruEmail ? 'Amel' : null),
          birthDate: data['birthDate'] as String?,
          address: data['address'] as String?,
          phoneNumber: data['phoneNumber'] as String?,
          extraField: data['extraField'] as String?,
        );
      } else {
        // Create Firestore document if it does not exist
        final defaultUser = AppUser(
          uid: firebaseUser.uid,
          email: email,
          displayName: isGuruEmail ? 'Amel, S.Pd.' : 'Pengguna',
          role: defaultRole,
          nickname: isGuruEmail ? 'Amel' : null,
          birthDate: isGuruEmail ? '15 Agustus 1990' : null,
          address: isGuruEmail ? 'Jl. Raya Megamendung No. 10, Bogor' : null,
          phoneNumber: isGuruEmail ? '089512345678' : null,
          extraField: isGuruEmail ? 'Guru Matematika' : null,
        );
        
        await _firestore.collection('users').doc(firebaseUser.uid).set({
          'displayName': defaultUser.displayName,
          'role': defaultUser.role,
          'nickname': defaultUser.nickname,
          'birthDate': defaultUser.birthDate,
          'address': defaultUser.address,
          'phoneNumber': defaultUser.phoneNumber,
          'extraField': defaultUser.extraField,
          if (!isGuruEmail) ...{
            'classId': 'XI',
            'roomId': 'Room_A',
          }
        });

        return defaultUser;
      }
    } catch (_) {
      // Safe fallback
    }

    return AppUser(
      uid: firebaseUser.uid,
      email: email,
      displayName: firebaseUser.displayName ?? (isGuruEmail ? 'Amel, S.Pd.' : 'Pengguna'),
      role: defaultRole,
      nickname: isGuruEmail ? 'Amel' : firebaseUser.displayName?.split(' ').first,
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
