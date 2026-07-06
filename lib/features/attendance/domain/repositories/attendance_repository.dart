import '../entities/attendance_record.dart';
import '../entities/student_attendance.dart';

abstract interface class AttendanceRepository {
  Future<List<AttendanceRecord>> getAttendanceHistory(String uid, DateTime month);
  Future<void> submitAttendance(String uid, AttendanceRecord record);
  Future<List<StudentAttendance>> getTodayStudentsAttendance();
}
