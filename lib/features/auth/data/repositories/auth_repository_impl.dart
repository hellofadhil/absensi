import 'package:firebase_core/firebase_core.dart';
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
    
    // Check if email exists in Firestore to distinguish unregistered accounts
    final userQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: trimmedEmail)
        .limit(1)
        .get();
    if (userQuery.docs.isEmpty) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Email belum terdaftar.',
      );
    }

    UserCredential credential;
    try {
      credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
    } on FirebaseAuthException {
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
    final email = firebaseUser.email?.trim() ?? '';

    try {
      var doc = await _firestore.collection('users').doc(firebaseUser.uid).get();

      // If document does not exist by UID, check if document exists by email
      // (e.g. when admin registered student beforehand with a generated doc ID)
      if ((!doc.exists || doc.data() == null) && email.isNotEmpty) {
        final querySnap = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        DocumentSnapshot<Map<String, dynamic>>? matchedDoc;
        if (querySnap.docs.isNotEmpty) {
          matchedDoc = querySnap.docs.first;
        } else {
          // Fallback check with lowercase email
          final lowerQuerySnap = await _firestore
              .collection('users')
              .where('email', isEqualTo: email.toLowerCase())
              .limit(1)
              .get();
          if (lowerQuerySnap.docs.isNotEmpty) {
            matchedDoc = lowerQuerySnap.docs.first;
          }
        }

        if (matchedDoc != null && matchedDoc.exists && matchedDoc.data() != null) {
          final data = Map<String, dynamic>.from(matchedDoc.data()!);
          // Migrate/save data to actual firebaseUser.uid
          await _firestore.collection('users').doc(firebaseUser.uid).set(
                data,
                SetOptions(merge: true),
              );

          // Clean up old temporary doc ID if different
          if (matchedDoc.id != firebaseUser.uid) {
            try {
              await _firestore.collection('users').doc(matchedDoc.id).delete();
            } catch (_) {}
          }

          doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        }
      }

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final role = data['role'] as String? ?? 'siswa';

        return AppUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: data['displayName'] as String? ?? firebaseUser.displayName ?? 'Pengguna',
          role: role,
          avatarUrl: data['avatarUrl'] as String?,
          nickname: data['nickname'] as String?,
          birthDate: data['birthDate'] as String?,
          address: data['address'] as String?,
          phoneNumber: data['phoneNumber'] as String?,
          extraField: data['extraField'] as String?,
          classLevel: data['classLevel'] as String?,
          roomId: data['roomId'] as String?,
          roomName: data['roomName'] as String?,
          attendanceNumber: (data['attendanceNumber'] is num)
              ? (data['attendanceNumber'] as num).toInt()
              : int.tryParse(data['attendanceNumber']?.toString() ?? ''),
          titlePrefix: data['titlePrefix'] as String?,
          angkatan: data['angkatan']?.toString(),
          isFirstLogin: data['isFirstLogin'] as bool? ?? false,
        );
      } else {
        // Create clean default user document if none exists
        final defaultUser = AppUser(
          uid: firebaseUser.uid,
          email: email,
          displayName: firebaseUser.displayName ?? 'Pengguna',
          role: 'siswa',
          isFirstLogin: true,
        );

        await _firestore.collection('users').doc(firebaseUser.uid).set({
          'displayName': defaultUser.displayName,
          'email': email,
          'role': defaultUser.role,
          'isFirstLogin': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return defaultUser;
      }
    } catch (_) {
      // Safe fallback
    }

    return AppUser(
      uid: firebaseUser.uid,
      email: email,
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
      if (user.titlePrefix != null) 'titlePrefix': user.titlePrefix,
      if (user.roomId != null) 'roomId': user.roomId,
      if (user.roomName != null) 'roomName': user.roomName,
      if (user.classLevel != null) 'classLevel': user.classLevel,
      if (user.attendanceNumber != null) 'attendanceNumber': user.attendanceNumber,
      if (user.angkatan != null) 'angkatan': user.angkatan,
      'isFirstLogin': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updateUser(AppUser user) async {
    final userData = <String, dynamic>{
      'displayName': user.displayName.trim(),
      'role': user.role,
      if (user.titlePrefix != null) 'titlePrefix': user.titlePrefix,
      if (user.nickname != null) 'nickname': user.nickname,
      if (user.birthDate != null) 'birthDate': user.birthDate,
      if (user.address != null) 'address': user.address,
      if (user.phoneNumber != null) 'phoneNumber': user.phoneNumber,
      if (user.extraField != null) 'extraField': user.extraField,
      if (user.classLevel != null) 'classLevel': user.classLevel,
      if (user.roomId != null) 'roomId': user.roomId,
      if (user.roomName != null) 'roomName': user.roomName,
      if (user.attendanceNumber != null) 'attendanceNumber': user.attendanceNumber,
      if (user.angkatan != null) 'angkatan': user.angkatan,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(userData, SetOptions(merge: true));
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<List<AppUser>> getAllUsers() async {
    final querySnapshot = await _firestore.collection('users').get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      final extra = data['extraField'] as String? ?? '';
      final name = data['displayName'] as String? ?? '';
      var parsedRole = data['role'] as String? ?? 'siswa';
      if (data['role'] == null) {
        if (extra.startsWith('Guru') || name.contains('S.Pd') || name.contains('M.Pd')) {
          parsedRole = 'guru';
        }
      }
      return AppUser(
        uid: doc.id,
        email: data['email'] as String? ?? '',
        displayName: name.isNotEmpty ? name : 'Pengguna',
        role: parsedRole,
        avatarUrl: data['avatarUrl'] as String?,
        nickname: data['nickname'] as String?,
        birthDate: data['birthDate'] as String?,
        address: data['address'] as String?,
        phoneNumber: data['phoneNumber'] as String?,
        extraField: extra.isNotEmpty ? extra : null,
        classLevel: data['classLevel'] as String?,
        roomId: data['roomId'] as String?,
        roomName: data['roomName'] as String?,
        attendanceNumber: (data['attendanceNumber'] is num)
            ? (data['attendanceNumber'] as num).toInt()
            : int.tryParse(data['attendanceNumber']?.toString() ?? ''),
        titlePrefix: data['titlePrefix'] as String?,
        angkatan: data['angkatan']?.toString(),
        isFirstLogin: data['isFirstLogin'] as bool? ?? false,
      );
    }).toList();
  }

  @override
  Future<void> createUser(AppUser user, {String? password}) async {
    final docRef = _firestore.collection('users').doc();
    var targetUid = user.uid.isNotEmpty ? user.uid : docRef.id;

    if (password != null && password.isNotEmpty && user.email.isNotEmpty) {
      try {
        final secondaryApp = await Firebase.initializeApp(
          name: 'SecondaryAuthApp_${DateTime.now().millisecondsSinceEpoch}',
          options: Firebase.app().options,
        );
        final credential = await FirebaseAuth.instanceFor(app: secondaryApp)
            .createUserWithEmailAndPassword(
          email: user.email.trim(),
          password: password,
        );
        if (credential.user != null) {
          targetUid = credential.user!.uid;
          await credential.user!.updateDisplayName(user.displayName.trim());
        }
        await secondaryApp.delete();
      } catch (_) {
        // Fallback: Proceed creating Firestore document
      }
    }

    final userData = <String, dynamic>{
      'email': user.email.trim(),
      'displayName': user.displayName.trim(),
      'role': user.role,
      if (user.titlePrefix != null) 'titlePrefix': user.titlePrefix,
      if (user.nickname != null) 'nickname': user.nickname,
      if (user.birthDate != null) 'birthDate': user.birthDate,
      if (user.address != null) 'address': user.address,
      if (user.phoneNumber != null) 'phoneNumber': user.phoneNumber,
      if (user.extraField != null) 'extraField': user.extraField,
      if (user.classLevel != null) 'classLevel': user.classLevel,
      if (user.roomId != null) 'roomId': user.roomId,
      if (user.roomName != null) 'roomName': user.roomName,
      if (user.attendanceNumber != null) 'attendanceNumber': user.attendanceNumber,
      if (user.angkatan != null) 'angkatan': user.angkatan,
      'isFirstLogin': true,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('users').doc(targetUid).set(userData, SetOptions(merge: true));

    // Atomically increment studentCount for the classroom if user is a student
    if (user.role == 'siswa' && user.roomId != null && user.roomId!.isNotEmpty) {
      try {
        await _firestore
            .collection('classRooms')
            .doc(user.roomId)
            .update({'studentCount': FieldValue.increment(1)});
      } catch (_) {}
    }
  }

  @override
  Future<void> deleteUser(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        final role = data['role'] as String? ?? 'siswa';
        final roomId = data['roomId'] as String?;

        if (role == 'guru') {
          // 1. Unassign teacher as wali kelas from any classrooms
          final waliRooms = await _firestore
              .collection('classRooms')
              .where('guruWaliId', isEqualTo: uid)
              .get();
          for (final doc in waliRooms.docs) {
            await doc.reference.update({
              'guruWaliId': null,
              'guruWaliName': null,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }

          // 2. Remove teacher assignments
          final assignments = await _firestore
              .collection('teacherAssignments')
              .where('teacherUid', isEqualTo: uid)
              .get();
          for (final doc in assignments.docs) {
            await doc.reference.delete();
          }
        } else if (role == 'siswa' && roomId != null && roomId.isNotEmpty) {
          // Safely decrement studentCount on classroom
          final roomDoc = await _firestore.collection('classRooms').doc(roomId).get();
          if (roomDoc.exists) {
            final currentCount = (roomDoc.data()?['studentCount'] as num?)?.toInt() ?? 0;
            final newCount = (currentCount > 0) ? currentCount - 1 : 0;
            await _firestore.collection('classRooms').doc(roomId).update({
              'studentCount': newCount,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        // Clean up attendance subcollection records if any
        final attendanceSnap = await _firestore
            .collection('users')
            .doc(uid)
            .collection('attendance')
            .get();
        for (final attDoc in attendanceSnap.docs) {
          await attDoc.reference.delete();
        }
      }
    } catch (_) {}

    await _firestore.collection('users').doc(uid).delete();
  }
}
