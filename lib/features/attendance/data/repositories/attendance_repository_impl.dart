import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/student_attendance.dart';
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
        }, SetOptions(merge: true));
  }

  @override
  Future<List<StudentAttendance>> getTodayStudentsAttendance() async {
    try {
      final usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'siswa')
          .get();

      final now = DateTime.now();
      final dateId = '${now.year}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';

      final List<StudentAttendance> results = [];

      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final uid = userDoc.id;
        final name = userData['displayName'] as String? ?? 'Siswa';
        final email = userData['email'] as String? ?? '';
        final avatarUrl = userData['avatarUrl'] as String?;
        final phoneNumber = userData['phoneNumber'] as String?;
        final className = userData['class'] as String? ?? userData['className'] as String? ?? 'XI RPL 1';
        final roomName = userData['room'] as String? ?? userData['roomName'] as String? ?? 'Lab RPL';

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
            );
          }
        } catch (_) {}

        results.add(StudentAttendance(
          studentName: name,
          email: email,
          avatarUrl: avatarUrl,
          phoneNumber: phoneNumber,
          className: className,
          roomName: roomName,
          record: record,
        ));
      }

      if (results.isEmpty) {
        // Fallback demo data
        final today = DateTime.now();
        return [
          StudentAttendance(
            studentName: 'Ahmad Fauzi',
            email: 'ahmad@smktibazma.sch.id',
            phoneNumber: '+62 812-3456-7890',
            className: 'XI RPL 1',
            roomName: 'Lab Komputer',
            record: AttendanceRecord(
              date: today,
              status: AttendanceStatus.hadir,
              checkInTime: DateTime(today.year, today.month, today.day, 6, 45),
              remarks: 'Dalam area sekolah',
            ),
          ),
          StudentAttendance(
            studentName: 'Budi Santoso',
            email: 'budi@smktibazma.sch.id',
            phoneNumber: '+62 823-4567-8901',
            className: 'XI RPL 1',
            roomName: 'Lab Komputer',
            record: AttendanceRecord(
              date: today,
              status: AttendanceStatus.terlambat,
              checkInTime: DateTime(today.year, today.month, today.day, 7, 12),
              remarks: 'Terlambat 12 menit - Kendaraan macet',
            ),
          ),
          StudentAttendance(
            studentName: 'Citra Lestari',
            email: 'citra@smktibazma.sch.id',
            phoneNumber: '+62 856-7890-1234',
            className: 'XI RPL 2',
            roomName: 'Ruang 204',
            record: AttendanceRecord(
              date: today,
              status: AttendanceStatus.sakit,
              remarks: 'Demam tinggi, ada surat dokter',
            ),
          ),
          StudentAttendance(
            studentName: 'Dwi Cahyo',
            email: 'dwi@smktibazma.sch.id',
            phoneNumber: '+62 899-0123-4567',
            className: 'XI RPL 2',
            roomName: 'Ruang 204',
            record: null, // Belum presensi
          ),
          StudentAttendance(
            studentName: 'Eka Wijaya',
            email: 'eka@smktibazma.sch.id',
            phoneNumber: '+62 812-8888-9999',
            className: 'X RPL 1',
            roomName: 'Ruang 102',
            record: AttendanceRecord(
              date: today,
              status: AttendanceStatus.izin,
              remarks: 'Acara pernikahan keluarga',
            ),
          ),
        ];
      }

      return results;
    } catch (_) {
      return [];
    }
  }
}
