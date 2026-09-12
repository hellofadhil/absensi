import 'attendance_record.dart';

class TeacherAttendance {
  final String teacherName;
  final String email;
  final String? avatarUrl;
  final String? phoneNumber;
  final AttendanceRecord? record;

  const TeacherAttendance({
    required this.teacherName,
    required this.email,
    this.avatarUrl,
    this.phoneNumber,
    this.record,
  });
}
