import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/student_attendance.dart';
import '../../domain/entities/teacher_attendance.dart';
import '../../domain/repositories/attendance_repository.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<AttendanceRecord>> getAttendanceHistory(String uid, DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1).subtract(const Duration(microseconds: 1));

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('date', isLessThanOrEqualTo: end.toIso8601String())
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AttendanceRecord(
          date: DateTime.parse(data['date'] as String),
          status: AttendanceStatus.values.byName(data['status'] as String? ?? 'none'),
          checkInTime: data['checkInTime'] != null ? DateTime.parse(data['checkInTime'] as String) : null,
          remarks: data['remarks'] as String?,
          latitude: (data['latitude'] as num?)?.toDouble(),
          longitude: (data['longitude'] as num?)?.toDouble(),
          attachmentUrl: data['attachmentUrl'] as String?,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> submitAttendance(String uid, AttendanceRecord record) async {
    // Generate date string format YYYY-MM-DD to serve as a unique document ID
    final dateId = '${record.date.year}-'
        '${record.date.month.toString().padLeft(2, '0')}-'
        '${record.date.day.toString().padLeft(2, '0')}';

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('attendance')
        .doc(dateId)
        .set({
          'date': record.date.toIso8601String(),
          'status': record.status.name,
          'checkInTime': record.checkInTime?.toIso8601String(),
          'remarks': record.remarks,
          'latitude': record.latitude,
          'longitude': record.longitude,
          'attachmentUrl': record.attachmentUrl,
        }, SetOptions(merge: true));
  }

  @override
  Future<List<StudentAttendance>> getTodayStudentsAttendance() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();

      final now = DateTime.now();
      final dateId = '${now.year}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';

      final List<StudentAttendance> results = [];

      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final role = userData['role'] as String? ?? 'siswa';
        final extra = userData['extraField'] as String? ?? '';
        final name = userData['displayName'] as String? ?? '';

        var isGuru = role == 'guru';
        if (userData['role'] == null &&
            (extra.startsWith('Guru') ||
                name.contains('S.Pd') ||
                name.contains('M.Pd'))) {
          isGuru = true;
        }
        if (isGuru || role == 'admin') continue;

        final uid = userDoc.id;
        final email = userData['email'] as String? ?? '';
        final avatarUrl = userData['avatarUrl'] as String?;
        final phoneNumber = userData['phoneNumber'] as String?;
        final className = userData['roomName'] as String? ??
            userData['classLevel'] as String? ??
            userData['class'] as String? ??
            userData['className'] as String? ??
            'Kelas Siswa';
        final roomName = userData['roomName'] as String? ??
            userData['room'] as String? ??
            userData['classLevel'] as String? ??
            'Kelas Siswa';

        final attendanceNum = (userData['attendanceNumber'] is num)
            ? (userData['attendanceNumber'] as num).toInt()
            : int.tryParse(userData['attendanceNumber']?.toString() ?? '');

        // Fetch today's attendance record
        AttendanceRecord? record;
        try {
          final attendanceDoc = await _firestore
              .collection('users')
              .doc(uid)
              .collection('attendance')
              .doc(dateId)
              .get();

          if (attendanceDoc.exists && attendanceDoc.data() != null) {
            final data = attendanceDoc.data()!;
            record = AttendanceRecord(
              date: DateTime.parse(data['date'] as String),
              status: AttendanceStatus.values.byName(data['status'] as String? ?? 'none'),
              checkInTime: data['checkInTime'] != null ? DateTime.parse(data['checkInTime'] as String) : null,
              remarks: data['remarks'] as String?,
              latitude: (data['latitude'] as num?)?.toDouble(),
              longitude: (data['longitude'] as num?)?.toDouble(),
              attachmentUrl: data['attachmentUrl'] as String?,
            );
          }
        } catch (_) {}

        results.add(StudentAttendance(
          studentName: name.isNotEmpty ? name : 'Siswa',
          email: email,
          avatarUrl: avatarUrl,
          phoneNumber: phoneNumber,
          className: className,
          roomName: roomName,
          attendanceNumber: attendanceNum,
          angkatan: userData['angkatan']?.toString(),
          record: record,
        ));
      }

      return results;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<TeacherAttendance>> getTodayTeachersAttendance() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();

      final now = DateTime.now();
      final dateId = '${now.year}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';

      final List<TeacherAttendance> results = [];

      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final role = userData['role'] as String? ?? 'siswa';
        final extra = userData['extraField'] as String? ?? '';
        final name = userData['displayName'] as String? ?? '';

        var isGuru = role == 'guru';
        if (userData['role'] == null &&
            (extra.startsWith('Guru') ||
                name.contains('S.Pd') ||
                name.contains('M.Pd'))) {
          isGuru = true;
        }
        if (!isGuru) continue;

        final uid = userDoc.id;
        final email = userData['email'] as String? ?? '';
        final avatarUrl = userData['avatarUrl'] as String?;
        final phoneNumber = userData['phoneNumber'] as String?;

        // Fetch today's attendance record
        AttendanceRecord? record;
        try {
          final attendanceDoc = await _firestore
              .collection('users')
              .doc(uid)
              .collection('attendance')
              .doc(dateId)
              .get();

          if (attendanceDoc.exists && attendanceDoc.data() != null) {
            final data = attendanceDoc.data()!;
            record = AttendanceRecord(
              date: DateTime.parse(data['date'] as String),
              status: AttendanceStatus.values.byName(data['status'] as String? ?? 'none'),
              checkInTime: data['checkInTime'] != null ? DateTime.parse(data['checkInTime'] as String) : null,
              remarks: data['remarks'] as String?,
              latitude: (data['latitude'] as num?)?.toDouble(),
              longitude: (data['longitude'] as num?)?.toDouble(),
              attachmentUrl: data['attachmentUrl'] as String?,
            );
          }
        } catch (_) {}

        results.add(TeacherAttendance(
          teacherName: name.isNotEmpty ? name : 'Guru',
          email: email,
          avatarUrl: avatarUrl,
          phoneNumber: phoneNumber,
          record: record,
        ));
      }

      return results;
    } catch (_) {
      return [];
    }
  }
}
