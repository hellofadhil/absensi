import 'package:absensi/features/attendance/domain/entities/attendance_record.dart';
import 'package:absensi/features/attendance/domain/entities/student_attendance.dart';
import 'package:absensi/features/attendance/domain/entities/teacher_attendance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AttendanceRecord & Entities Unit Tests', () {
    test('AttendanceRecord holds values correctly', () {
      final now = DateTime.now();
      final record = AttendanceRecord(
        date: now,
        status: AttendanceStatus.hadir,
        checkInTime: now,
        latitude: -6.1234,
        longitude: 106.1234,
        remarks: 'Hadir tepat waktu',
      );

      expect(record.status, equals(AttendanceStatus.hadir));
      expect(record.latitude, equals(-6.1234));
      expect(record.longitude, equals(106.1234));
      expect(record.remarks, equals('Hadir tepat waktu'));
    });

    test('StudentAttendance holds student details and record', () {
      const student = StudentAttendance(
        studentName: 'Ahmad Fadhil',
        email: 'fadhil@sekolah.com',
        className: 'XI RPL 1',
        roomName: 'Lab Software',
        record: null,
      );

      expect(student.studentName, equals('Ahmad Fadhil'));
      expect(student.className, equals('XI RPL 1'));
      expect(student.record, isNull);
    });

    test('TeacherAttendance holds teacher details and record', () {
      const teacher = TeacherAttendance(
        teacherName: 'Budi Santoso',
        email: 'budi@sekolah.com',
        phoneNumber: '08123456789',
        record: null,
      );

      expect(teacher.teacherName, equals('Budi Santoso'));
      expect(teacher.phoneNumber, equals('08123456789'));
      expect(teacher.record, isNull);
    });
  });
}
