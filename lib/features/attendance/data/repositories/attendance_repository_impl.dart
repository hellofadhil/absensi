import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/attendance_record.dart';
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
}
