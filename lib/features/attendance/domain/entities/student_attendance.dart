import 'attendance_record.dart';

class StudentAttendance {
  final String studentName;
  final String email;
  final String? avatarUrl;
  final String? phoneNumber;
  final String? className;
  final String? roomName;
  final int? attendanceNumber;
  final String? angkatan;
  final AttendanceRecord? record;

  const StudentAttendance({
    required this.studentName,
    required this.email,
    this.avatarUrl,
    this.phoneNumber,
    this.className,
    this.roomName,
    this.attendanceNumber,
    this.angkatan,
    this.record,
  });

  String? get formattedAttendanceNumber =>
      attendanceNumber != null ? 'No. ${attendanceNumber.toString().padLeft(2, '0')}' : null;

  /// Returns the formatted batch/generation, e.g. "Angkatan 12".
  String? get formattedAngkatan {
    if (angkatan == null || angkatan!.trim().isEmpty) return null;
    final trimmed = angkatan!.trim();
    if (trimmed.toLowerCase().startsWith('angkatan')) return trimmed;
    return 'Angkatan $trimmed';
  }
}
