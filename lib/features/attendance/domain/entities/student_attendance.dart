import 'attendance_record.dart';

class StudentAttendance {
  final String studentName;
  final String email;
  final String? avatarUrl;
  final String? phoneNumber;
  final String? className;
  final String? roomName;
  final AttendanceRecord? record;

  const StudentAttendance({
    required this.studentName,
    required this.email,
    this.avatarUrl,
    this.phoneNumber,
    this.className,
    this.roomName,
    this.record,
  });
}
